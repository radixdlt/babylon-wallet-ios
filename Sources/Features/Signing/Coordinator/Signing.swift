import Cryptography
import CustomDump
import DeviceFactorSourceClient
import EngineToolkitModels
import FactorSourcesClient
import FeaturePrelude
import Profile
import struct ROLAClient.AuthenticationDataToSignForChallengeResponse
import TransactionClient

// MARK: - K1.PublicKey + CustomDumpStringConvertible
extension K1.PublicKey: CustomDumpStringConvertible {
	public var customDumpDescription: String {
		self.compressedRepresentation.hex
	}
}

// MARK: - CompileTransactionIntentResponse + CustomDumpStringConvertible
extension CompileTransactionIntentResponse: CustomDumpStringConvertible {
	public var customDumpDescription: String {
		compiledIntent.hex
	}
}

// MARK: - CompileNotarizedTransactionIntentResponse + CustomDumpStringConvertible
extension CompileNotarizedTransactionIntentResponse: CustomDumpStringConvertible {
	public var customDumpDescription: String {
		compiledIntent.hex
	}
}

// MARK: - SigningPurposeWithPayload
public enum SigningPurposeWithPayload: Sendable, Hashable {
	case signAuth(AuthenticationDataToSignForChallengeResponse)

	case signTransaction(
		ephemeralNotaryPrivateKey: Curve25519.Signing.PrivateKey,
		CompileTransactionIntentResponse,
		origin: SigningPurpose.SignTransactionPurpose
	)

	var purpose: SigningPurpose {
		switch self {
		case .signAuth: return .signAuth
		case let .signTransaction(_, _, purpose): return .signTransaction(purpose)
		}
	}

	var dataToSign: Data {
		switch self {
		case let .signAuth(auth): return auth.payloadToHashAndSign
		case let .signTransaction(_, compiledIntent, _): return Data(compiledIntent.compiledIntent)
		}
	}
}

// MARK: - SigningResponse
public enum SigningResponse: Sendable, Hashable {
	case signTransaction(NotarizeTransactionResponse, origin: SigningPurpose.SignTransactionPurpose)
	case signAuth(SignedAuthChallenge)
}

// MARK: - Signing
public struct Signing: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Step: Sendable, Hashable {
			case signWithDeviceFactors(SignWithFactorSourcesOfKindDevice.State)
			case signWithLedgerFactors(SignWithFactorSourcesOfKindLedger.State)
		}

		public var signatures: OrderedSet<SignatureOfEntity> = []

		public var step: Step

		public var factorsLeftToSignWith: SigningFactors
		public let expectedSignatureCount: Int
		public let signingPurposeWithPayload: SigningPurposeWithPayload

		public init(
			factorsLeftToSignWith: SigningFactors,
			signingPurposeWithPayload: SigningPurposeWithPayload
		) {
			precondition(!factorsLeftToSignWith.isEmpty)
			self.signingPurposeWithPayload = signingPurposeWithPayload
			self.factorsLeftToSignWith = factorsLeftToSignWith
			self.expectedSignatureCount = factorsLeftToSignWith.expectedSignatureCount
			self.step = Signing.nextStep(
				factorsLeftToSignWith: factorsLeftToSignWith,
				signingPurposeWithPayload: signingPurposeWithPayload
			)!
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case finishedSigningWithAllFactors
		case notarizeResult(TaskResult<NotarizeTransactionResponse>)
	}

	public enum ChildAction: Sendable, Equatable {
		case signWithDeviceFactors(SignWithFactorSourcesOfKindDevice.Action)
		case signWithLedgerFactors(SignWithFactorSourcesOfKindLedger.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case finishedSigning(SigningResponse)
		case failedToSign
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.transactionClient) var transactionClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.step, action: /.self) {
			Scope(
				state: /State.Step.signWithDeviceFactors,
				action: /Action.child .. ChildAction.signWithDeviceFactors
			) {
				SignWithFactorSourcesOfKindDevice()
			}
			Scope(
				state: /State.Step.signWithLedgerFactors,
				action: /Action.child .. ChildAction.signWithLedgerFactors
			) {
				SignWithFactorSourcesOfKindLedger()
			}
		}

		Reduce(self.core)
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case .finishedSigningWithAllFactors:
			switch state.signingPurposeWithPayload {
			case let .signAuth(authData):
				let response = SignedAuthChallenge(challenge: authData.input.challenge, entitySignatures: Set(state.signatures))
				return .send(.delegate(.finishedSigning(.signAuth(response))))
			case let .signTransaction(ephemeralNotaryPrivateKey, compiledIntent, _):
				let notaryKey: SLIP10.PrivateKey = .curve25519(ephemeralNotaryPrivateKey)

				return .run { [signatures = state.signatures] send in
					await send(.internal(.notarizeResult(TaskResult {
						let intentSignatures: Set<Engine.SignatureWithPublicKey> = try Set(signatures.map {
							try $0.signatureWithPublicKey.intoEngine()
						})
						return try await transactionClient.notarizeTransaction(.init(
							intentSignatures: intentSignatures,
							compileTransactionIntent: compiledIntent,
							notary: notaryKey
						))
					})))
				}
			}

		case let .notarizeResult(.failure(error)):
			loggerGlobal.error("Failed to notarize transaction, error: \(error)")
			errorQueue.schedule(error)
			return .none
		case let .notarizeResult(.success(notarized)):
			switch state.signingPurposeWithPayload {
			case .signAuth:
				assertionFailure("Discrepancy")
				loggerGlobal.warning("Discrepancy in signing, notarized a tx, but state.signingPurposeWithPayload == .signAuth, not possible.")
				return .none

			case let .signTransaction(_, _, purpose):
				return .send(.delegate(.finishedSigning(.signTransaction(notarized, origin: purpose))))
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case
			let .signWithDeviceFactors(.delegate(.done(factors, signatures))),
			let .signWithLedgerFactors(.delegate(.done(factors, signatures))):
			return handleSignatures(signingFactors: factors, signatures: signatures, &state)
		default:
			return .none
		}
	}

	private func handleSignatures(
		signingFactors: NonEmpty<Set<SigningFactor>>,
		signatures: Set<SignatureOfEntity>,
		_ state: inout State
	) -> EffectTask<Action> {
		state.signatures.append(contentsOf: signatures)
		let kind = signingFactors.first.factorSource.kind
		precondition(signingFactors.allSatisfy { $0.factorSource.kind == kind })
		state.factorsLeftToSignWith.removeValue(forKey: kind)

		return .fireAndForget { [purpose = state.signingPurposeWithPayload.purpose] in
			try? await factorSourcesClient.updateLastUsed(.init(
				factorSourceIDs: signingFactors.map(\.factorSource.id),
				usagePurpose: purpose
			))
		}.concatenate(with: proceedWithNextFactorSource(&state))
	}

	private func proceedWithNextFactorSource(_ state: inout State) -> EffectTask<Action> {
		guard let nextStep = Self.nextStep(
			factorsLeftToSignWith: state.factorsLeftToSignWith,
			signingPurposeWithPayload: state.signingPurposeWithPayload
		) else {
			assert(state.signatures.count == state.expectedSignatureCount, "Expected to have \(state.expectedSignatureCount) signatures, but got: \(state.signatures.count)")
			return .send(.internal(.finishedSigningWithAllFactors))
		}
		state.step = nextStep
		return .none
	}

	private static func nextStep(
		factorsLeftToSignWith: SigningFactors,
		signingPurposeWithPayload: SigningPurposeWithPayload
	) -> State.Step? {
		guard
			let nextKind = factorsLeftToSignWith.keys.first,
			let nextFactors = factorsLeftToSignWith[nextKind]
		else {
			return nil
		}
		switch nextKind {
		case .device:
			return .signWithDeviceFactors(.init(signingFactors: nextFactors, signingPurposeWithPayload: signingPurposeWithPayload))
		case .ledgerHQHardwareWallet:
			return .signWithLedgerFactors(.init(signingFactors: nextFactors, signingPurposeWithPayload: signingPurposeWithPayload))
		}
	}
}
