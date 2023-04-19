import AccountsClient
import Cryptography
import FeaturePrelude
import PersonasClient

// MARK: - GenesisFactorSourceSelection
public enum GenesisFactorSourceSelection: Sendable, Hashable {
	case device(BabylonDeviceFactorSource)
	case ledger
}

// MARK: - CreationOfEntity
public struct CreationOfEntity<Entity: EntityProtocol>: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let networkID: NetworkID?
		public let name: NonEmptyString
		public let genesisFactorSourceSelection: GenesisFactorSourceSelection

		public init(
			networkID: NetworkID?,
			name: NonEmptyString,
			genesisFactorSourceSelection: GenesisFactorSourceSelection
		) {
			self.networkID = networkID
			self.name = name
			self.genesisFactorSourceSelection = genesisFactorSourceSelection
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
			switch state.genesisFactorSourceSelection {
			case let .device(babylonDeviceFactorSource):
				return createEntityControlledByDeviceFactorSource(babylonDeviceFactorSource, state: state)
			case .ledger:
				fatalError("impl me")
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

extension CreationOfEntity {
	private func createEntityControlledByDeviceFactorSource(
		_ babylonFactorSource: BabylonDeviceFactorSource,
		state: State
	) -> EffectTask<Action> {
		let entityKind = Entity.entityKind

		let request = CreateVirtualEntityControlledByDeviceFactorSourceRequest(
			networkID: state.networkID,
			babylonDeviceFactorSource: babylonFactorSource,
			displayName: state.name,
			extraProperties: { numberOfEntities in
				switch entityKind {
				case .identity: return .forPersona(.init(fields: []))
				case .account: return .forAccount(.init(numberOfAccountsOnNetwork: numberOfEntities))
				}
			}
		)

		return .run { send in
			await send(.internal(.createEntityResult(TaskResult {
				switch entityKind {
				case .account:
					let account = try await accountsClient.newUnsavedVirtualAccountControlledByDeviceFactorSource(request)
					try await accountsClient.saveVirtualAccount(.init(
						account: account,
						shouldUpdateFactorSourceNextDerivationIndex: true
					))
					return try account.cast()
				case .identity:
					let persona = try await personasClient.newUnsavedVirtualPersonaControlledByDeviceFactorSource(request)
					try await personasClient.saveVirtualPersona(persona)
					return try persona.cast()
				}
			}
			)))
		}
	}
}
