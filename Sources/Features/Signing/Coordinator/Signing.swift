import Cryptography
import FactorSourcesClient
import FeaturePrelude
import Profile
import TransactionClient
import UseFactorSourceClient

// MARK: - Signing
public struct Signing: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Step: Sendable, Hashable {
			case prepare(PrepareForSigning.State)
			case signWithDevice(SignWithDeviceFactorSource.State)
			case signWithLedger(SignWithLedgerFactorSource.State)
		}

		public let feePayerSelectionAmongstCandidates: FeePayerSelectionAmongstCandidates

		public var step: Step

		public var compiledIntent: CompileTransactionIntentResponse? = nil
		public var factorsLeftToSignWith: OrderedSet<SigningFactor> = []
		public var expectedSignatureCount = -1
		public var signatures: OrderedSet<Signature> = []
		private let ephemeralNotaryPrivateKey: Curve25519.Signing.PrivateKey

		public init(
			networkID: NetworkID,
			manifest: TransactionManifest,
			feePayerSelectionAmongstCandidates: FeePayerSelectionAmongstCandidates
		) {
			let ephemeralNotaryPrivateKey = Curve25519.Signing.PrivateKey()
			self.step = .prepare(.init(
				manifest: manifest,
				networkID: networkID,
				feePayer: feePayerSelectionAmongstCandidates.selected.account,
				ephemeralNotaryPublicKey: ephemeralNotaryPrivateKey.publicKey
			))
			self.ephemeralNotaryPrivateKey = ephemeralNotaryPrivateKey
			self.feePayerSelectionAmongstCandidates = feePayerSelectionAmongstCandidates
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case finishedSigningWithAllFactors
		case notarizeResult(TaskResult<NotarizeTransactionResponse>)
	}

	public enum ChildAction: Sendable, Equatable {
		case prepare(PrepareForSigning.Action)
		case signWithDevice(SignWithDeviceFactorSource.Action)
		case signWithLedger(SignWithLedgerFactorSource.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case notarized(NotarizeTransactionResponse)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.transactionClient) var transactionClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.step, action: /.self) {
			Scope(
				state: /State.Step.prepare,
				action: /Action.child .. ChildAction.prepare
			) {
				PrepareForSigning()
			}
			Scope(
				state: /State.Step.signWithDevice,
				action: /Action.child .. ChildAction.signWithDevice
			) {
				SignWithDeviceFactorSource()
			}
			Scope(
				state: /State.Step.signWithLedger,
				action: /Action.child .. ChildAction.signWithLedger
			) {
				SignWithLedgerFactorSource()
			}
		}

		Reduce(self.core)
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case .finishedSigningWithAllFactors:
			guard let compiledIntent = state.compiledIntent else {
				assertionFailure("Expected compiledIntent")
				return .none
			}
			let notaryKey: SLIP10.PrivateKey = .curve25519(.init())

			return .run { [signatures = state.signatures] send in
				await send(.internal(.notarizeResult(TaskResult {
					let intentSignatures: try Set<Engine.SignatureWithPublicKey> = Set(signatures.map {
						$0.signatureWithPublicKey.intoEngine()
					})
					return try await transactionClient.notarizeTransaction(.init(
						intentSignatures: intentSignatures,
						compileTransactionIntent: compiledIntent,
						notary: notaryKey
					))
				})))
			}
		case let .notarizeResult(.failure(error)):
			loggerGlobal.error("Failed to notarize transaction, error: \(error)")
			errorQueue.schedule(error)
			return .none
		case let .notarizeResult(.success(notarized)):
			return .send(.delegate(.notarized(notarized)))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .prepare(.delegate(.failedToBuildTX)):
			return .none
		case .prepare(.delegate(.failedToLoadSigners)):
			return .none
		case let .prepare(.delegate(.done(compiledIntent, signingFactors))):
			state.compiledIntent = compiledIntent
			state.factorsLeftToSignWith = signingFactors.rawValue
			state.expectedSignatureCount = signingFactors.flatMap { sf in
				sf.signers.map(\.factorInstancesRequiredToSign.count)
			}.reduce(0, +)
			return proceedWithNextFactorSource(&state)

		case
			let .signWithDevice(.delegate(.done(f, s))),
			let .signWithLedger(.delegate(.done(f, s))):
			return handleSignatures(signingFactor: f, signatures: s, &state)
		default:
			return .none
		}
	}

	private func handleSignatures(
		signingFactor: SigningFactor,
		signatures: Set<AccountSignature>,
		_ state: inout State
	) -> EffectTask<Action> {
		let factorSource = signingFactor.factorSource
		state.signatures.append(contentsOf: signatures.map(\.signature))
		state.factorsLeftToSignWith.removeAll(where: { $0.factorSource == factorSource })
		return proceedWithNextFactorSource(&state)
	}

	private func proceedWithNextFactorSource(_ state: inout State) -> EffectTask<Action> {
		guard let intent = state.compiledIntent else {
			assertionFailure("expected intent")
			return .none
		}
		if let next = state.factorsLeftToSignWith.first {
			let dataToSign = Data(intent.compiledIntent)
			switch next.factorSource.kind {
			case .device:
				state.step = .signWithDevice(.init(signingFactor: next, dataToSign: dataToSign))
			case .ledgerHQHardwareWallet:
				state.step = .signWithLedger(.init(signingFactor: next, dataToSign: dataToSign))
			}
			return .none
		} else {
			assert(state.signatures.count == state.expectedSignatureCount)
			return .send(.internal(.finishedSigningWithAllFactors))
		}
	}
}
