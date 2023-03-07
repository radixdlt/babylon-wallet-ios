import FeaturePrelude
import NewConnectionFeature
import P2PConnectivityClient

// MARK: - ManageP2PClients
public struct ManageP2PClients: Sendable, ReducerProtocol {
	@Dependency(\.p2pConnectivityClient) var p2pConnectivityClient
	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.errorQueue) var errorQueue
	public init() {}
}

extension ManageP2PClients {
	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.forEach(\.clients, action: /Action.child .. Action.ChildAction.connection) {
				ManageP2PClient()
			}
			.presentationDestination(\.$destination, action: /Action.child .. Action.ChildAction.destination) {
				Destinations()
			}
	}

	public func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.task)):
			return .run { send in
				await send(.internal(.system(.loadClientsResult(
					TaskResult {
						try await p2pConnectivityClient.getP2PClients()
					}
				))))
			}

		case let .internal(.system(.loadClientsResult(.success(clientsFromProfile)))):
			state.clients = .init(
				uniqueElements: clientsFromProfile.map { ManageP2PClient.State(client: $0) }
			)

			return .none

		case let .internal(.system(.loadClientsResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.saveNewConnectionResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.saveNewConnectionResult(.success(newConnection)))):
			state.clients.append(
				ManageP2PClient.State(client: newConnection)
			)
			return .none

		case let .child(.connection(id, .delegate(.deleteConnection))):
			return .task {
				let result = await TaskResult {
					try await p2pConnectivityClient.deleteP2PClientByPassword(id)
					return id
				}
				return .internal(.system(.deleteConnectionResult(result)))
			}

		case let .internal(.system(.deleteConnectionResult(.success(deletedID)))):
			state.clients.remove(id: deletedID)
			return .none

		case let .internal(.system(.deleteConnectionResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case .internal(.view(.addNewConnectionButtonTapped)):
			state.destination = .newConnection(.init())
			return .none

		case let .child(.destination(.presented(.newConnection(.delegate(.newConnection(connectedClient)))))):
			state.destination = nil
			return .run { send in
				await send(.internal(.system(.saveNewConnectionResult(
					TaskResult {
						try await p2pConnectivityClient.storeP2PClient(
							connectedClient
						)
					}.map { connectedClient }
				))))
			}

		case .child(.destination(.presented(.newConnection(.delegate(.dismiss))))):
			state.destination = nil
			return .none

		case .child:
			return .none
		}
	}
}
