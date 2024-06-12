import ComposableArchitecture
import SwiftUI

struct OverlayReducer: Sendable, FeatureReducer {
	struct State: Hashable, Sendable {
		var itemsQueue: OrderedSet<OverlayWindowClient.Item> = []

		var isPresenting: Bool {
			destination != nil
		}

		@PresentationState
		public var destination: Destination.State?
	}

	enum ViewAction: Sendable, Equatable {
		case task
	}

	enum InternalAction: Sendable, Equatable {
		case scheduleItem(OverlayWindowClient.Item)
		case showNextItemIfPossible
	}

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case hud(HUD.State)
			case alert(OverlayWindowClient.Item.AlertState)
			case linkDappSheet(LinkingToDapp.State)
			case fullScreen(FullScreenOverlayCoordinator.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case hud(HUD.Action)
			case alert(OverlayWindowClient.Item.AlertAction)
			case linkDappSheet(LinkingToDapp.Action)
			case fullScreen(FullScreenOverlayCoordinator.Action)
		}

		public var body: some Reducer<State, Action> {
			Scope(state: \.hud, action: \.hud) {
				HUD()
			}

			Scope(state: /State.linkDappSheet, action: /Action.linkDappSheet) {
				LinkingToDapp()
			}

			Scope(state: \.fullScreen, action: \.fullScreen) {
				FullScreenOverlayCoordinator()
			}
		}
	}

	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.continuousClock) var clock
	var userDefaults = UserDefaults.Dependency.radix

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
			return dismiss(&state)

		case .hud(.delegate(.dismiss)):
			return dismiss(&state)

		case .linkDappSheet(.delegate(.continueFlow)):
			if let item = state.itemsQueue.first, case let .autodismissSheet(id, _) = item {
				overlayWindowClient.sendAlertAction(.primaryButtonTapped, id)
			}

			return dismiss(&state)

		case .linkDappSheet(.delegate(.cancel)):
			if let item = state.itemsQueue.first, case let .autodismissSheet(id, _) = item {
				overlayWindowClient.sendAlertAction(.dismissed, id)
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
		case let .alert(alert):
			state.destination = .alert(alert)
			return setIsUserInteractionEnabled(&state, isEnabled: true)

		case let .autodismissSheet(_, dAppMetadata):
			state.destination = .linkDappSheet(.init(
				dismissDelay: userDefaults.getDappLinkingDelay(),
				autoDismissEnabled: userDefaults.getDappLinkingAutoContinueEnabled(),
				dAppMetadata: dAppMetadata
			))

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
