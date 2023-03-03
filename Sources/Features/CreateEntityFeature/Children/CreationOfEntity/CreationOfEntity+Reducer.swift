import AccountsClient
import Cryptography
import FeaturePrelude
import PersonasClient

// MARK: - CreationOfEntity
public struct CreationOfEntity<Entity: EntityProtocol>: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let curve: Slip10Curve
		public let networkID: NetworkID?
		public let name: NonEmpty<String>
		public let genesisFactorInstanceDerivationStrategy: GenesisFactorInstanceDerivationStrategy

		public init(
			curve: Slip10Curve,
			networkID: NetworkID?,
			name: NonEmpty<String>,
			genesisFactorInstanceDerivationStrategy: GenesisFactorInstanceDerivationStrategy
		) {
			self.curve = curve
			self.networkID = networkID
			self.name = name
			self.genesisFactorInstanceDerivationStrategy = genesisFactorInstanceDerivationStrategy
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum InternalAction: Sendable, Equatable {
		case createEntityResult(TaskResult<Entity>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case createdEntity(Entity)
		case createEntityFailed
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.personasClient) var personasClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { [networkID = state.networkID, genesisFactorInstanceDerivationStrategy = state.genesisFactorInstanceDerivationStrategy, name = state.name, curve = state.curve] send in
				await send(.internal(.createEntityResult(TaskResult {
					let entityKind = Entity.entityKind
					let request = try CreateVirtualEntityRequest(
						curve: curve,
						networkID: networkID,
						genesisFactorInstanceDerivationStrategy: genesisFactorInstanceDerivationStrategy,
						entityKind: entityKind,
						displayName: name
					)

					switch entityKind {
					case .account:
						let account = try await accountsClient.createUnsavedVirtualAccount(request: request)
						try await accountsClient.saveVirtualAccount(account)
						return try account.cast()
					case .identity:
						let persona = try await personasClient.createUnsavedVirtualPersona(request: request)
						try await personasClient.saveVirtualPersona(persona)
						return try persona.cast()
					}
				}
				)))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case .createEntityResult(.failure):
			return .send(.delegate(.createEntityFailed))

		case let .createEntityResult(.success(entity)):
			return .send(.delegate(.createdEntity(entity)))
		}
	}
}
