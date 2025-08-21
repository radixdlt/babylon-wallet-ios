import ComposableArchitecture
import SwiftUI

// MARK: - P2PLinksFeature
struct P2PLinksFeature: Sendable, FeatureReducer {
	// MARK: State

	struct State: Sendable, Hashable {
		var links: IdentifiedArrayOf<P2PLink>

		@PresentationState
		var destination: Destination.State?

		init(
			links: IdentifiedArrayOf<P2PLink> = .init(),
			destination: Destination.State? = nil
		) {
			self.links = links
			self.destination = destination
		}
	}

	// MARK: Action

	enum ViewAction: Sendable, Equatable {
		case task
		case addNewConnectionButtonTapped
		case removeButtonTapped(P2PLink)
		case editButtonTapped(P2PLink)
	}

	enum InternalAction: Sendable, Equatable {
		case loadLinksResult(TaskResult<OrderedSet<P2PLink>>)
		case deleteConnectionResult(TaskResult<P2PLink>)
	}

	// MARK: Destination

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case newConnection(NewConnection.State)
			case removeConnection(AlertState<Action.RemoveConnection>)
			case updateName(RenameLabel.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case newConnection(NewConnection.Action)
			case removeConnection(RemoveConnection)
			case updateName(RenameLabel.Action)

			enum RemoveConnection: Sendable, Hashable {
				case removeTapped(P2PLink)
			}
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.newConnection, action: \.newConnection) {
				NewConnection()
			}
			Scope(state: \.updateName, action: \.updateName) {
				RenameLabel()
			}
		}
	}

	// MARK: Reducer

	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.errorQueue) var errorQueue

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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
			state.destination = .updateName(.init(kind: .connector(link)))
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadLinksResult(.success(linksFromProfile)):
			state.links = linksFromProfile.elements.asIdentified()
			return .none

		case let .loadLinksResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .deleteConnectionResult(.success(p2pLink)):
			state.links.remove(p2pLink)
			return .none

		case let .deleteConnectionResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .newConnection(.delegate(.newConnection(connectedClient))):
			state.destination = nil
			state.links.updateOrAppend(connectedClient)
			return .none

		case let .removeConnection(.removeTapped(p2pLink)):
			return .run { send in
				let result = await TaskResult {
					try await radixConnectClient.deleteP2PLinkByPassword(p2pLink.connectionPassword)
					return p2pLink
				}
				await send(.internal(.deleteConnectionResult(result)))
			}

		case let .updateName(.delegate(.labelUpdated(.connector(link)))):
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
