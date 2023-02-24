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
		CombineReducers {
			EmptyReducer()
				.forEach(\.clients, action: /Action.child .. Action.ChildAction.connection) {
					ManageP2PClient()
				}
				.ifLet(
					\.newConnection,
					action: /Action.child .. Action.ChildAction.newConnection
				) {
					NewConnection()
				}

			Reduce(self.core)
		}
	}

	public func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.task)):
			return .run { send in
				do {
					for try await p2pClientIDs in try await p2pConnectivityClient.getP2PClientIDs() {
						guard !Task.isCancelled else {
							return
						}
						await send(.internal(.system(.loadClientIDsResult(
							.success(p2pClientIDs)
						))))
					}
				} catch {
					await send(.internal(.system(.loadClientIDsResult(
						.failure(error)
					))))
				}
			}

		case let .internal(.system(.loadClientIDsResult(.success(clientIDs)))):
			guard !clientIDs.isEmpty else {
				return .none
			}
			return .run { send in
				await send(.internal(.system(.loadClientsByIDsResult(
					TaskResult {
						try await p2pConnectivityClient.getP2PClientsByIDs(clientIDs)
					}
				))))
			}

		case let .internal(.system(.loadClientIDsResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.loadClientsByIDsResult(.success(clientsFromProfile)))):

			state.clients = .init(
				uniqueElements: clientsFromProfile.map { ManageP2PClient.State(client: $0) }
			)

			return .none

		case let .internal(.system(.loadClientsByIDsResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.saveNewConnectionResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.saveNewConnectionResult(.success(newConnection)))):
			state.clients.append(
				ManageP2PClient.State(clientWithConnectionStatus: newConnection)
			)
			return .none

		case .internal(.view(.dismissButtonTapped)):
			return .run { send in
				await send(.delegate(.dismiss))
			}
//		#if DEBUG
//		case let .child(.connection(id, .delegate(.sendTestMessage))):
//			return .run { send in
//				await send(.internal(.system(.sendTestMessageResult(
//					TaskResult {
//						let msg = "Test"
//						try await self.p2pConnectivityClient._sendTestMessage(id, msg)
//						return msg
//					}
//				))))
//			}
//		#endif

		case let .child(.connection(id, .delegate(.deleteConnection))):
			return .run { send in
				await send(.internal(.system(.deleteConnectionResult(
					TaskResult {
						try await p2pConnectivityClient.deleteP2PClientByID(id)
						return id
					}
				))))
			}

		case let .internal(.system(.deleteConnectionResult(.success(deletedID)))):
			state.clients.remove(id: deletedID)
			return .none

		case let .internal(.system(.deleteConnectionResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case .internal(.system(.sendTestMessageResult(.success(_)))):
			return .none

		case let .internal(.system(.sendTestMessageResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case .internal(.view(.addNewConnectionButtonTapped)):
			state.newConnection = .init()
			return .none

		case let .child(.newConnection(.delegate(.newConnection(connectedClient)))):
			state.newConnection = nil
			return .run { send in
				await send(.internal(.system(.saveNewConnectionResult(
					TaskResult {
						try await p2pConnectivityClient.addP2PClientWithConnection(
							connectedClient.p2pClient
						)
					}.map { connectedClient }
				))))
			}

		case .child(.newConnection(.delegate(.dismiss))):
			state.newConnection = nil
			return .none

		case .child, .delegate:
			return .none
		}
	}
}
