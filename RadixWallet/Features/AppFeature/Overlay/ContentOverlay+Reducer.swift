import ComposableArchitecture
import SwiftUI

struct ContentOverlay: Sendable, FeatureReducer {
	struct State: Hashable, Sendable {
		var itemsQueue: OrderedSet<OverlayWindowClient.Item.Content> = []

		var isPresenting: Bool {
			destination != nil
		}

		@PresentationState
		var destination: Destination.State?
	}

	enum ViewAction: Sendable, Equatable {
		case task
	}

	enum InternalAction: Sendable, Equatable {
		case scheduleItem(OverlayWindowClient.Item.Content)
		case showNextItemIfPossible
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case sheet(SheetOverlayCoordinator.State)
			case fullScreen(FullScreenOverlayCoordinator.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case sheet(SheetOverlayCoordinator.Action)
			case fullScreen(FullScreenOverlayCoordinator.Action)
		}

		var body: some Reducer<State, Action> {
			Scope(state: \.sheet, action: \.sheet) {
				SheetOverlayCoordinator()
			}
			Scope(state: \.fullScreen, action: \.fullScreen) {
				FullScreenOverlayCoordinator()
			}
		}
	}

	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.continuousClock) var clock
	@Dependency(\.contactSupportClient) var contactSupport

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			.run { send in
				for try await item in overlayWindowClient.scheduledContent() {
					await send(.internal(.scheduleItem(item)))
				}
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .scheduleItem(event):
			state.itemsQueue.append(event)
			return showItemIfPossible(state: &state)
		case .showNextItemIfPossible:
			return showItemIfPossible(state: &state)
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .sheet(.delegate(action)):
			if case let .sheet(state) = state.itemsQueue.first {
				overlayWindowClient.sendSheetAction(action, state.id)
			}
			return dismiss(&state)

		case let .fullScreen(.delegate(action)):
			if case let .fullScreen(state) = state.itemsQueue.first {
				overlayWindowClient.sendFullScreenAction(action, state.id)
			}
			return dismiss(&state)

		default:
			return .none
		}
	}

	func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		switch state.itemsQueue.first {
		case let .fullScreen(state):
			overlayWindowClient.sendFullScreenAction(.dismiss, state.id)
		default:
			break
		}

		return dismiss(&state)
	}

	private func showItemIfPossible(state: inout State) -> Effect<Action> {
		guard let presentedItem = state.itemsQueue.first else {
			return .none
		}

		if state.isPresenting {
			return .none
		}

		switch presentedItem {
		case let .sheet(sheet):
			state.destination = .sheet(sheet)
			return setIsUserInteractionEnabled(&state, isEnabled: true)

		case let .fullScreen(fullScreen):
			state.destination = .fullScreen(fullScreen)
			return setIsUserInteractionEnabled(&state, isEnabled: true)
		}
	}

	private func dismiss(_ state: inout State) -> Effect<Action> {
		state.destination = nil
		state.itemsQueue.removeFirst()
		return setIsUserInteractionEnabled(&state, isEnabled: false)
			.concatenate(with: showItemIfPossible(state: &state))
	}

	/// Sets the interaction enabled on the window, by implication this will also enable/disable the interaction
	/// with the main app window. When showing an Alert, we don't want users to be able to interact with the main app window for example.
	private func setIsUserInteractionEnabled(_ state: inout State, isEnabled: Bool) -> Effect<Action> {
		overlayWindowClient.setIsContentUserIteractionEnabled(isEnabled)
		return .none
	}
}
