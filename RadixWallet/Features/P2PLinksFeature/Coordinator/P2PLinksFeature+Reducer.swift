import ComposableArchitecture
import SwiftUI

// MARK: - P2PLinksFeature
public struct P2PLinksFeature: Sendable, FeatureReducer {
	// MARK: State

	public struct State: Sendable, Hashable {
		public var links: IdentifiedArrayOf<P2PLinkRow.State>

		@PresentationState
		public var destination: Destination.State?

		public init(
			links: IdentifiedArrayOf<P2PLinkRow.State> = .init(),
			destination: Destination.State? = nil
		) {
			self.links = links
			self.destination = destination
		}
	}

	// MARK: Action

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
		case connection(id: ConnectionPassword, action: P2PLinkRow.Action)
	}

	// MARK: Destination

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case newConnection(NewConnection.State)
			case removeConnection(AlertState<Action.RemoveConnection>)
		}

		public enum Action: Sendable, Equatable {
			case newConnection(NewConnection.Action)
			case removeConnection(RemoveConnection)

			public enum RemoveConnection: Sendable, Hashable {
				case removeTapped(ConnectionPassword)
			}
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.newConnection, action: /Action.newConnection) {
				NewConnection()
			}
		}
	}

	// MARK: Reducer

	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.links, action: /Action.child .. ChildAction.connection) {
				P2PLinkRow()
			}
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				let result = await TaskResult { try await radixConnectClient.getP2PLinks() }
				await send(.internal(.loadLinksResult(result)))
			}

		case .addNewConnectionButtonTapped:
			state.destination = .newConnection(.init())
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadLinksResult(.success(linksFromProfile)):
			state.links = .init(
				uniqueElements: linksFromProfile.map { P2PLinkRow.State(link: $0) }
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
				P2PLinkRow.State(link: newConnection)
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

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .connection(id, .delegate(.deleteConnection)):
			state.destination = .removeConnection(.confirmRemoval(id: id))
			return .none
		default:
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .newConnection(.delegate(.newConnection(connectedClient))):
			state.destination = nil
			return .run { send in
				let result = await TaskResult {
					try await radixConnectClient.storeP2PLink(connectedClient)
				}
				.map { connectedClient }

				await send(.internal(.saveNewConnectionResult(result)))
			}

		case .newConnection(.delegate(.dismiss)):
			state.destination = nil
			return .none

		case let .removeConnection(.removeTapped(id)):
			return .run { send in
				let result = await TaskResult {
					try await radixConnectClient.deleteP2PLinkByPassword(id)
					return id
				}
				await send(.internal(.deleteConnectionResult(result)))
			}

		default:
			return .none
		}
	}
}

extension AlertState<P2PLinksFeature.Destination.Action.RemoveConnection> {
	static func confirmRemoval(id: ConnectionPassword) -> AlertState {
		AlertState {
			TextState(L10n.LinkedConnectors.RemoveConnectionAlert.title)
		} actions: {
			ButtonState(role: .destructive, action: .removeTapped(id)) {
				TextState(L10n.LinkedConnectors.RemoveConnectionAlert.removeButtonTitle)
			}
			ButtonState(role: .cancel) {
				TextState(L10n.Common.cancel)
			}
		} message: {
			TextState(L10n.LinkedConnectors.RemoveConnectionAlert.message)
		}
	}
}
