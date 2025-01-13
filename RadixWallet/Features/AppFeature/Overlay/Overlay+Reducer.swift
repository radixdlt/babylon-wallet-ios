import ComposableArchitecture
import SwiftUI

struct OverlayReducer: Sendable, FeatureReducer {
	struct State: Hashable, Sendable {
		var itemsQueue: OrderedSet<OverlayWindowClient.Item> = []

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
		case scheduleItem(OverlayWindowClient.Item)
		case showNextItemIfPossible
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case hud(HUD.State)
			case sheet(SheetOverlayCoordinator.State)
			case alert(OverlayWindowClient.Item.AlertState)
			case fullScreen(FullScreenOverlayCoordinator.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case hud(HUD.Action)
			case sheet(SheetOverlayCoordinator.Action)
			case alert(OverlayWindowClient.Item.AlertAction)
			case fullScreen(FullScreenOverlayCoordinator.Action)
		}

		var body: some Reducer<State, Action> {
			Scope(state: \.hud, action: \.hud) {
				HUD()
			}
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
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			.run { send in
				for try await item in overlayWindowClient.scheduledItems() {
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
		case let .alert(action):
			if case let .alert(state) = state.itemsQueue.first {
				overlayWindowClient.sendAlertAction(action, state.id)
			}
			if case let .emailSupport(additionalInfo) = action {
				return .run { _ in
					await contactSupport.openEmail(additionalInfo)
				}
				.concatenate(with: dismiss(&state))
			}
			return dismiss(&state)

		case .hud(.delegate(.dismiss)):
			return dismiss(&state)

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
		case let .alert(state):
			overlayWindowClient.sendAlertAction(.dismissed, state.id)
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
			if case .hud = presentedItem {
				// A HUD is force dismissed when next item comes in, AKA it is a lower priority.
				state.destination = nil
				state.itemsQueue.removeFirst()
				return .run { send in
					// Hacky - A very minor delay is needed before showing the next item is a HUD.
					try await clock.sleep(for: .milliseconds(100))
					await send(.internal(.showNextItemIfPossible))
				}
			} else {
				return .none
			}
		}

		switch presentedItem {
		case let .hud(hud):
			state.destination = .hud(.init(content: hud))
			return .none

		case let .sheet(sheet):
			state.destination = .sheet(sheet)
			return setIsUserInteractionEnabled(&state, isEnabled: true)

		case let .alert(alert):
			state.destination = .alert(alert)
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
		overlayWindowClient.setIsUserIteractionEnabled(isEnabled)
		return .none
	}
}
