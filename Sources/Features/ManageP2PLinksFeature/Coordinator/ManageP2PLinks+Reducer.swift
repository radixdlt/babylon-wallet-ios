import FeaturePrelude
import NewConnectionFeature
import RadixConnectClient

// MARK: - ManageP2PLinks
public struct ManageP2PLinks: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var links: IdentifiedArrayOf<ManageP2PLink.State>

		@PresentationState
		public var destination: Destinations.State?

		public init(
			links: IdentifiedArrayOf<ManageP2PLink.State> = .init(),
			destination: Destinations.State? = nil
		) {
			self.links = links
			self.destination = destination
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case addNewConnectionButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadLinksResult(TaskResult<OrderedSet<P2PLink>>)
		case saveNewConnectionResult(TaskResult<P2PLink>)
		case deleteConnectionResult(TaskResult<ConnectionPassword>)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
		case connection(
			id: ConnectionPassword,
			action: ManageP2PLink.Action
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
			.forEach(\.links, action: /Action.child .. ChildAction.connection) {
				ManageP2PLink()
			}
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				await send(.internal(.loadLinksResult(
					TaskResult {
						try await radixConnectClient.getP2PLinks()
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
		case let .loadLinksResult(.success(clientsFromProfile)):
			state.links = .init(
				uniqueElements: clientsFromProfile.map { ManageP2PLink.State(client: $0) }
			)
			return .none

		case let .loadLinksResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .saveNewConnectionResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .saveNewConnectionResult(.success(newConnection)):
			state.links.append(
				ManageP2PLink.State(client: newConnection)
			)
			return .none

		case let .deleteConnectionResult(.success(deletedID)):
			state.links.remove(id: deletedID)
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
					try await radixConnectClient.deleteP2PLinkByPassword(id)
					return id
				}
				return .internal(.deleteConnectionResult(result))
			}

		case let .destination(.presented(.newConnection(.delegate(.newConnection(connectedClient))))):
			state.destination = nil
			return .run { send in
				await send(.internal(.saveNewConnectionResult(
					TaskResult {
						try await radixConnectClient.storeP2PLink(
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
