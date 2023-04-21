import AccountsClient
import Cryptography
import FeaturePrelude
import PersonasClient

// MARK: - CreationOfEntity
public struct CreationOfEntity<Entity: EntityProtocol>: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let request: CreateVirtualEntityRequest
		public var name: NonEmptyString {
			request.displayName
		}

		public init(request: CreateVirtualEntityRequest) {
			self.request = request
		}

		public init(
			curve: SLIP10.Curve,
			networkID: NetworkID?,
			name: NonEmptyString,
			babylonFactorSource: BabylonDeviceFactorSource
		) {
			self.init(
				request: .init(
					curve: curve,
					networkID: networkID,
					babylonDeviceFactorSource: babylonFactorSource,
					displayName: name
				)
			)
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
			let entityKind = Entity.entityKind
			return .run { [request = state.request] send in
				await send(.internal(.createEntityResult(TaskResult {
					switch entityKind {
					case .account:
						let account = try await accountsClient.createUnsavedVirtualAccount(request)
						try await accountsClient.saveVirtualAccount(.init(
							account: account,
							shouldUpdateFactorSourceNextDerivationIndex: true
						))
						return try account.cast()
					case .identity:
						let persona = try await personasClient.createUnsavedVirtualPersona(request)
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
