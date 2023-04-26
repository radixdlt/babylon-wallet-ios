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

		public var compiledIntent: CompileTransactionIntentResponse? = nil
		public let ephemeralNotaryPublicKey: Curve25519.Signing.PublicKey?
		public init(
			manifest: TransactionManifest,
			networkID: NetworkID,
			feePayer: Profile.Network.Account,
			ephemeralNotaryPublicKey: Curve25519.Signing.PublicKey?
		) {
			self.manifest = manifest
			self.networkID = networkID
			self.feePayer = feePayer
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
			let accounts = NonEmpty(
				rawValue: Set(transactionIntentWithSigners.notaryAndSigners.accountsNeededToSign + [state.feePayer])
			)!
			do {
				state.compiledIntent = try engineToolkitClient.compileTransactionIntent(transactionIntentWithSigners.intent)
				return loadSigningFactors(networkID: state.networkID, accounts: accounts)
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
						selectNotary: { involvedAccounts in
							if let ephemeralNotaryPublicKey = state.ephemeralNotaryPublicKey {
								return .init(notary: .ephemeralPublicKey(.eddsaEd25519(ephemeralNotaryPublicKey)), notaryAsSignatory: false)
							} else {
								return .init(notary: .account(involvedAccounts.first))
							}
						}
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
}
