import ComposableArchitecture
import SwiftUI

// MARK: - Secp256k1PublicKey + CustomDumpStringConvertible
extension Secp256k1PublicKey: CustomDumpStringConvertible {
	public var customDumpDescription: String {
		self.hex
	}
}

// MARK: - SigningPurposeWithPayload
enum SigningPurposeWithPayload: Sendable, Hashable {
	case signAuth(AuthenticationDataToSignForChallengeResponse)

	case signTransaction(
		ephemeralNotaryPrivateKey: Curve25519.Signing.PrivateKey,
		TransactionIntent,
		origin: SigningPurpose.SignTransactionPurpose
	)

	var purpose: SigningPurpose {
		switch self {
		case .signAuth: .signAuth
		case let .signTransaction(_, _, purpose): .signTransaction(purpose)
		}
	}
}

// MARK: - SigningResponse
enum SigningResponse: Sendable, Hashable {
	case signTransaction(NotarizeTransactionResponse, origin: SigningPurpose.SignTransactionPurpose)
	case signAuth(SignedAuthChallenge)
}

// MARK: - Signing
struct Signing: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var signatures: OrderedSet<SignatureOfEntity> = []
		var signWithFactorSource: SignWithFactorSource.State

		var factorsLeftToSignWith: SigningFactors
		let expectedSignatureCount: Int
		let signingPurposeWithPayload: SigningPurposeWithPayload

		init(
			factorsLeftToSignWith: SigningFactors,
			signingPurposeWithPayload: SigningPurposeWithPayload
		) {
			precondition(!factorsLeftToSignWith.isEmpty)
			self.signingPurposeWithPayload = signingPurposeWithPayload
			self.factorsLeftToSignWith = factorsLeftToSignWith
			self.expectedSignatureCount = factorsLeftToSignWith.expectedSignatureCount
			self.signWithFactorSource = Signing.nextFactorSource(
				factorsLeftToSignWith: factorsLeftToSignWith,
				signingPurposeWithPayload: signingPurposeWithPayload
			)!
		}
	}

	enum InternalAction: Sendable, Equatable {
		case finishedSigningWithAllFactors
		case notarizeResult(TaskResult<NotarizeTransactionResponse>)
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case signWithFactorSource(SignWithFactorSource.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case cancelSigning
		case finishedSigning(SigningResponse)
		case failedToSign
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.transactionClient) var transactionClient

	init() {}

	var body: some ReducerOf<Self> {
		Scope(state: \.signWithFactorSource, action: /Action.child .. ChildAction.signWithFactorSource) {
			SignWithFactorSource()
		}
		Reduce(self.core)
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .finishedSigningWithAllFactors:
			switch state.signingPurposeWithPayload {
			case let .signAuth(authData):
				let response = SignedAuthChallenge(challenge: authData.input.challenge, entitySignatures: Set(state.signatures))
				return .send(.delegate(.finishedSigning(.signAuth(response))))
			case let .signTransaction(ephemeralNotaryPrivateKey, intent, _):

				return .run { [signatures = state.signatures] send in
					await send(.internal(.notarizeResult(TaskResult {
						let intentSignatures: Set<SignatureWithPublicKey> = Set(signatures.map(\.signatureWithPublicKey))
						return try await transactionClient.notarizeTransaction(.init(
							intentSignatures: intentSignatures,
							transactionIntent: intent,
							notary: ephemeralNotaryPrivateKey
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

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .signWithFactorSource(.delegate(.done(factors, signatures))):
			return handleSignatures(signingFactors: factors, signatures: signatures, &state)

		case let .signWithFactorSource(.delegate(.failedToSign(factor))):
			loggerGlobal.error("Failed to sign with \(factor.factorSource.kind)")
			return .send(.delegate(.failedToSign))

		case .signWithFactorSource(.delegate(.cancel)):
			return .send(.delegate(.cancelSigning))

		default:
			return .none
		}
	}

	private func handleSignatures(
		signingFactors: NonEmpty<Set<SigningFactor>>,
		signatures: Set<SignatureOfEntity>,
		_ state: inout State
	) -> Effect<Action> {
		state.signatures.append(contentsOf: signatures)
		let kind = signingFactors.first.factorSource.kind
		precondition(signingFactors.allSatisfy { $0.factorSource.kind == kind })
		state.factorsLeftToSignWith.removeValue(forKey: kind)

		return .run { [purpose = state.signingPurposeWithPayload.purpose] _ in
			try? await factorSourcesClient.updateLastUsed(.init(
				factorSourceIDs: signingFactors.map(\.factorSource.id),
				usagePurpose: purpose
			))
		}.concatenate(with: proceedWithNextFactorSource(&state))
	}

	private func proceedWithNextFactorSource(_ state: inout State) -> Effect<Action> {
		guard let nextFactorSource = Self.nextFactorSource(
			factorsLeftToSignWith: state.factorsLeftToSignWith,
			signingPurposeWithPayload: state.signingPurposeWithPayload
		) else {
			assert(state.signatures.count == state.expectedSignatureCount, "Expected to have \(state.expectedSignatureCount) signatures, but got: \(state.signatures.count)")
			return .send(.internal(.finishedSigningWithAllFactors))
		}
		state.signWithFactorSource = nextFactorSource
		return .none
	}

	private static func nextFactorSource(
		factorsLeftToSignWith: SigningFactors,
		signingPurposeWithPayload: SigningPurposeWithPayload
	) -> SignWithFactorSource.State? {
		guard
			let nextKind = factorsLeftToSignWith.keys.first,
			let nextFactors = factorsLeftToSignWith[nextKind]
		else {
			return nil
		}
		switch nextKind {
		case .device:
			return .init(
				kind: .device,
				signingFactors: nextFactors,
				signingPurposeWithPayload: signingPurposeWithPayload
			)
		case .ledgerHqHardwareWallet:
			return .init(
				kind: .ledger,
				signingFactors: nextFactors,
				signingPurposeWithPayload: signingPurposeWithPayload
			)
		default: fatalError("DISCREPANCY: Found non .device | .ledger factor source. A real world user cannot possible have this.")
		}
	}
}
