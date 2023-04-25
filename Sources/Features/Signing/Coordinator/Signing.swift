import Cryptography
import FactorSourcesClient
import FeaturePrelude
import Profile
import TransactionClient

// MARK: - Signature
public struct Signature: Sendable, Hashable {
	public let curve: SLIP10.Curve
	public let derivationPath: DerivationPath
	public let publicKey: SLIP10.PublicKey
	public let signature: SLIP10.Signature
}

// MARK: - Signing
public struct Signing: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Step: Sendable, Hashable {
			case signWithLedger(SignWithLedgerFactorSource.State)
		}

		public let networkID: NetworkID
		public let manifest: TransactionManifest
		public let feePayerSelectionAmongstCandidates: FeePayerSelectionAmongstCandidates

		public var step: Step?
		public var compiledIntent: CompileTransactionIntentResponse? = nil
		public var factorsLeftToSignWith: OrderedSet<SigningFactor> = []
		public var expectedSignatureCount = -1
		public var signatures: OrderedSet<Signature> = []

		public init(
			networkID: NetworkID,
			manifest: TransactionManifest,
			feePayerSelectionAmongstCandidates: FeePayerSelectionAmongstCandidates
		) {
			self.networkID = networkID
			self.manifest = manifest
			self.feePayerSelectionAmongstCandidates = feePayerSelectionAmongstCandidates
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case builtTransaction(TaskResult<TransactionIntentWithSigners>)
		case loadSigningFactors(TaskResult<SigningFactors>)
		case finishedSigningWithAllFactors
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum ChildAction: Sendable, Equatable {
		case signWithLedger(SignWithLedgerFactorSource.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case notarized(CompileNotarizedTransactionIntentResponse)
	}

	@Dependency(\.transactionClient) var transactionClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.engineToolkitClient) var engineToolkitClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(self.core)
			.ifLet(\.step, action: /Action.child) {
				Scope(state: /Signing.State.Step.signWithLedger, action: /ChildAction.signWithLedger) {
					SignWithLedgerFactorSource()
				}
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return buildTransaction(state)
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .builtTransaction(.failure(error)):
			errorQueue.schedule(error)
			loggerGlobal.error("Failed to build transaction, error: \(error)")
			return .none

		case let .builtTransaction(.success(transactionIntentWithSigners)):
			let accounts = NonEmpty(
				rawValue: Set(transactionIntentWithSigners.notaryAndSigners.accountsNeededToSign + [state.feePayerSelectionAmongstCandidates.selected.account])
			)!
			do {
				state.compiledIntent = try engineToolkitClient.compileTransactionIntent(transactionIntentWithSigners.intent)
				return loadSigningFactors(networkID: state.networkID, accounts: accounts)
			} catch {
				loggerGlobal.error("Failed to compile manifest: \(error)")
				errorQueue.schedule(error)
				return .none
			}

		case let .loadSigningFactors(.failure(error)):
			errorQueue.schedule(error)
			loggerGlobal.error("Failed to load factors of signers, error: \(error)")
			return .none

		case let .loadSigningFactors(.success(signingFactors)):
			state.factorsLeftToSignWith = signingFactors.rawValue
			state.expectedSignatureCount = signingFactors.flatMap { sf in
				sf.signers.map(\.factorInstancesRequiredToSign.count)
			}.reduce(0, +)
			return proceedWithNextFactorSource(state)

		case .finishedSigningWithAllFactors:
			loggerGlobal.critical("Notarize!")
			return .none
		}
	}

	private func buildTransaction(_ state: State) -> EffectTask<Action> {
		.run { [networkID = state.networkID, manifest = state.manifest] send in
			await send(.internal(.builtTransaction(
				TaskResult {
					try await transactionClient.buildTransactionIntent(.init(
						networkID: networkID,
						manifest: manifest
					)).get()
				}
			)))
		}
	}

	private func loadSigningFactors(networkID: NetworkID, accounts: NonEmpty<Set<Profile.Network.Account>>) -> EffectTask<Action> {
		.run { send in
			await send(.internal(.loadSigningFactors(
				TaskResult {
					try await factorSourcesClient.getSigningFactors(networkID, accounts)
				}
			)))
		}
	}

	private func proceedWithNextFactorSource(_ state: State) -> EffectTask<Action> {
		if let next = state.factorsLeftToSignWith.first {
			return signWithFactor(next)
		} else {
			assert(state.signatures.count == state.expectedSignatureCount)
			return .send(.internal(.finishedSigningWithAllFactors))
		}
	}

	private func signWithFactor(_ signingFactor: SigningFactor) -> EffectTask<Action> {
		switch signingFactor.factorSource.kind {
		case .device:
			return .run { _ in
			}
		case .ledgerHQHardwareWallet:
			return .run { _ in
			}
		}
	}
}
