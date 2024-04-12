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
		case autoDimissed
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case hud(HUD.State)
			case alert(OverlayWindowClient.Item.AlertState)
		}

		public enum Action: Sendable, Equatable {
			case hud(HUD.Action)
			case alert(OverlayWindowClient.Item.AlertAction)
		}

		public var body: some Reducer<State, Action> {
			Scope(state: /State.hud, action: /Action.hud) {
				HUD()
			}
		}
	}

	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.continuousClock) var clock

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
		case .autoDimissed:
			if let item = state.itemsQueue.first, case let .autodismissAlert(state) = item {
				overlayWindowClient.sendAlertAction(.dismissed, state.id)
			}
			return dismiss(&state)
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .alert(action):
			if let item = state.itemsQueue.first, case let .alert(state) = item {
				overlayWindowClient.sendAlertAction(action, state.id)
			}
			return dismiss(&state)
		case .hud(.delegate(.dismiss)):
			return dismiss(&state)

		default:
			return .none
		}
	}

	func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		dismissAlert(state: &state, withAction: .dismissed)
	}

	private func showItemIfPossible(state: inout State) -> Effect<Action> {
		guard !state.itemsQueue.isEmpty else {
			return .none
		}

		if state.isPresenting {
			guard let presentedItem = state.itemsQueue.first else {
				return .none
			}

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

		let nextItem = state.itemsQueue[0]

		switch nextItem {
		case let .hud(hud):
			state.destination = .hud(.init(content: hud))
			return .none
		case let .alert(alert):
			state.destination = .alert(alert)
			return setIsUserInteractionEnabled(&state, isEnabled: true)
		case let .autodismissAlert(alert):
			state.destination = .alert(alert)
			return setIsUserInteractionEnabled(&state, isEnabled: true).concatenate(with: .run { send in
				try await Task.sleep(for: .seconds(2))
				await send(.internal(.autoDimissed))
			})
		}
	}

	private func dismissAlert(state: inout State, withAction action: OverlayWindowClient.Item.AlertAction) -> Effect<Action> {
		let item = state.itemsQueue[0]
		if case let .alert(state) = item {
			overlayWindowClient.sendAlertAction(action, state.id)
		}

		return dismiss(&state)
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
