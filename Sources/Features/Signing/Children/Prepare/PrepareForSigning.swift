import Cryptography
import FactorSourcesClient
import FeaturePrelude
import TransactionClient

// MARK: - PrepareForSigning
public struct PrepareForSigning: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let manifest: TransactionManifest
		public let feePayer: Profile.Network.Account
		public let networkID: NetworkID
		public let purpose: SigningPurpose

		public var compiledIntent: CompileTransactionIntentResponse? = nil
		public let ephemeralNotaryPublicKey: Curve25519.Signing.PublicKey
		public init(
			manifest: TransactionManifest,
			networkID: NetworkID,
			feePayer: Profile.Network.Account,
			purpose: SigningPurpose,
			ephemeralNotaryPublicKey: Curve25519.Signing.PublicKey
		) {
			self.manifest = manifest
			self.networkID = networkID
			self.feePayer = feePayer
			self.purpose = purpose
			self.ephemeralNotaryPublicKey = ephemeralNotaryPublicKey
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum InternalAction: Sendable, Equatable {
		case builtTransaction(TaskResult<TransactionIntentWithSigners>)
		case loadSigningFactors(TaskResult<SigningFactors>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case failedToBuildTX
		case failedToLoadSigners
		case done(CompileTransactionIntentResponse, SigningFactors)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.transactionClient) var transactionClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.engineToolkitClient) var engineToolkitClient

	public init() {}

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
			return .send(.delegate(.failedToBuildTX))

		case let .builtTransaction(.success(transactionIntentWithSigners)):
			let entities = NonEmpty(
				rawValue: Set(Array(transactionIntentWithSigners.transactionSigners.intentSignerEntitiesOrEmpty()) + [.account(state.feePayer)])
			)!
			do {
				state.compiledIntent = try engineToolkitClient.compileTransactionIntent(transactionIntentWithSigners.intent)
				return loadSigningFactors(networkID: state.networkID, entities: entities, purpose: state.purpose)
			} catch {
				loggerGlobal.error("Failed to compile manifest: \(error)")
				errorQueue.schedule(error)
				return .send(.delegate(.failedToLoadSigners))
			}

		case let .loadSigningFactors(.failure(error)):
			errorQueue.schedule(error)
			loggerGlobal.error("Failed to load factors of signers, error: \(error)")
			return .none

		case let .loadSigningFactors(.success(signingFactors)):
			guard let compiledIntent = state.compiledIntent else {
				assertionFailure("Expected compiled intent")
				return .none
			}
			return .send(.delegate(.done(compiledIntent, signingFactors)))
		}
	}

	private func buildTransaction(_ state: State) -> EffectTask<Action> {
		.run { send in
			await send(.internal(.builtTransaction(
				TaskResult {
					try await transactionClient.buildTransactionIntent(.init(
						networkID: state.networkID,
						manifest: state.manifest,
						ephemeralNotaryPublicKey: state.ephemeralNotaryPublicKey
					))
				}
			)))
		}
	}

	private func loadSigningFactors(
		networkID: NetworkID,
		entities: NonEmpty<Set<EntityPotentiallyVirtual>>,
		purpose: SigningPurpose
	) -> EffectTask<Action> {
		.run { send in
			await send(.internal(.loadSigningFactors(
				TaskResult {
					try await factorSourcesClient.getSigningFactors(.init(
						networkID: networkID,
						signers: entities,
						signingPurpose: purpose
					))
				}
			)))
		}
	}
}
