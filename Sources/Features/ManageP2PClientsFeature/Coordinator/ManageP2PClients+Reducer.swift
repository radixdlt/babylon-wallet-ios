import FeaturePrelude
import NewConnectionFeature
import RadixConnectClient

// MARK: - ManageP2PClients
public struct ManageP2PClients: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var clients: IdentifiedArrayOf<ManageP2PClient.State>

		@PresentationState
		public var destination: Destinations.State?

		public init(
			clients: IdentifiedArrayOf<ManageP2PClient.State> = .init(),
			destination: Destinations.State? = nil
		) {
			self.clients = clients
			self.destination = destination
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case addNewConnectionButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadClientsResult(TaskResult<OrderedSet<P2PClient>>)
		case saveNewConnectionResult(TaskResult<P2PClient>)
		case deleteConnectionResult(TaskResult<ConnectionPassword>)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationActionOf<ManageP2PClients.Destinations>)
		case connection(
			id: ConnectionPassword,
			action: ManageP2PClient.Action
		)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case newConnection(NewConnection.State)
		}

		public enum Action: Sendable, Equatable {
			case newConnection(NewConnection.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.newConnection, action: /Action.newConnection) {
				NewConnection()
			}
		}
	}

	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.forEach(\.clients, action: /Action.child .. ChildAction.connection) {
				ManageP2PClient()
			}
			.presentationDestination(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				await send(.internal(.loadClientsResult(
					TaskResult {
						try await radixConnectClient.getP2PClients()
					}
				)))
			}

		case .addNewConnectionButtonTapped:
			state.destination = .newConnection(.init())
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadClientsResult(.success(clientsFromProfile)):
			state.clients = .init(
				uniqueElements: clientsFromProfile.map { ManageP2PClient.State(client: $0) }
			)
			return .none

		case let .loadClientsResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .saveNewConnectionResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .saveNewConnectionResult(.success(newConnection)):
			state.clients.append(
				ManageP2PClient.State(client: newConnection)
			)
			return .none

		case let .deleteConnectionResult(.success(deletedID)):
			state.clients.remove(id: deletedID)
			return .none

		case let .deleteConnectionResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .connection(id, .delegate(.deleteConnection)):
			return .task {
				let result = await TaskResult {
					try await radixConnectClient.deleteP2PClientByPassword(id)
					return id
				}
				return .internal(.deleteConnectionResult(result))
			}

		case let .destination(.presented(.newConnection(.delegate(.newConnection(connectedClient))))):
			state.destination = nil
			return .run { send in
				await send(.internal(.saveNewConnectionResult(
					TaskResult {
						try await radixConnectClient.storeP2PClient(
							connectedClient
						)
					}.map { connectedClient }
				)))
			}

		case .destination(.presented(.newConnection(.delegate(.dismiss)))):
			state.destination = nil
			return .none

		default:
			return .none
		}
	}
}
