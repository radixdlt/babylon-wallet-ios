import ComposableArchitecture
import SwiftUI

// MARK: - P2PLinksFeature
public struct P2PLinksFeature: Sendable, FeatureReducer {
	// MARK: State

	public struct State: Sendable, Hashable {
		public var links: IdentifiedArrayOf<P2PLink>

		@PresentationState
		public var destination: Destination.State?

		public init(
			links: IdentifiedArrayOf<P2PLink> = .init(),
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
		case removeButtonTapped(P2PLink)
		case editButtonTapped(P2PLink)
	}

	public enum InternalAction: Sendable, Equatable {
		case loadLinksResult(TaskResult<OrderedSet<P2PLink>>)
		case saveNewConnectionResult(TaskResult<P2PLink>)
		case deleteConnectionResult(TaskResult<P2PLink>)
	}

	// MARK: Destination

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case newConnection(NewConnection.State)
			case removeConnection(AlertState<Action.RemoveConnection>)
			case updateName(UpdateP2PLinkName.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case newConnection(NewConnection.Action)
			case removeConnection(RemoveConnection)
			case updateName(UpdateP2PLinkName.Action)

			public enum RemoveConnection: Sendable, Hashable {
				case removeTapped(P2PLink)
			}
		}

		public var body: some ReducerOf<Self> {
			Scope(state: \.newConnection, action: \.newConnection) {
				NewConnection()
			}
			Scope(state: \.updateName, action: \.updateName) {
				UpdateP2PLinkName()
			}
		}
	}

	// MARK: Reducer

	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
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

		case let .removeButtonTapped(link):
			state.destination = .removeConnection(.confirmRemoval(link: link))
			return .none

		case let .editButtonTapped(link):
			state.destination = .updateName(.init(link: link))
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadLinksResult(.success(linksFromProfile)):
			state.links = .init(uniqueElements: linksFromProfile)
			return .none

		case let .loadLinksResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .saveNewConnectionResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .saveNewConnectionResult(.success(newConnection)):
			state.links.updateOrAppend(newConnection)
			return .none

		case let .deleteConnectionResult(.success(p2pLink)):
			state.links.remove(p2pLink)
			return .none

		case let .deleteConnectionResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .newConnection(.delegate(.newConnection(connectedClient))):
			state.destination = nil
			return .run { send in
				let result = await TaskResult {
					try await radixConnectClient.updateOrAddP2PLink(connectedClient)
				}
				.map { connectedClient }

				await send(.internal(.saveNewConnectionResult(result)))
			}

		case let .removeConnection(.removeTapped(p2pLink)):
			return .run { send in
				let result = await TaskResult {
					try await radixConnectClient.deleteP2PLinkByPassword(p2pLink.connectionPassword)
					return p2pLink
				}
				await send(.internal(.deleteConnectionResult(result)))
			}

		case let .updateName(.delegate(.linkNameUpdated(link))):
			state.links.updateOrAppend(link)
			state.destination = nil
			return .none

		default:
			return .none
		}
	}
}

extension AlertState<P2PLinksFeature.Destination.Action.RemoveConnection> {
	static func confirmRemoval(link: P2PLink) -> AlertState {
		AlertState {
			TextState(L10n.LinkedConnectors.RemoveConnectionAlert.title)
		} actions: {
			ButtonState(role: .destructive, action: .removeTapped(link)) {
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
