import FeaturePrelude
import OverlayWindowClient
import SwiftUI

struct OverlayReducer: Sendable, FeatureReducer {
	struct State: Hashable, Sendable {
		var itemsQueue: OrderedSet<OverlayWindowClient.Item> = []

		var isPresenting: Bool {
			alert != nil || hud != nil
		}

		@PresentationState
		public var alert: Alerts.State?
		public var hud: HUD.State?
	}

	struct Alerts: Sendable, ReducerProtocol {
		typealias State = OverlayWindowClient.Item.AlertState
		typealias Action = OverlayWindowClient.Item.AlertAction

		var body: some ReducerProtocolOf<Self> {
			EmptyReducer()
		}
	}

	enum ViewAction: Sendable, Equatable {
		case task
		case alert(PresentationAction<Alerts.Action>)
	}

	enum InternalAction: Sendable, Equatable {
		case scheduleItem(OverlayWindowClient.Item)
		case showNextItemIfPossible
	}

	enum ChildAction: Sendable, Equatable {
		case hud(HUD.Action)
	}

	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.continuousClock) var clock

	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$alert, action: /Action.view .. ViewAction.alert) {
				Alerts()
			}
			.ifLet(\.hud, action: /Action.child .. ChildAction.hud) {
				HUD()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				for try await item in overlayWindowClient.scheduledItems() {
					await send(.internal(.scheduleItem(item)))
				}
			}
		case .alert(.dismiss):
			return dismissAlert(state: &state, withAction: .dismissed)
		case let .alert(.presented(action)):
			return dismissAlert(state: &state, withAction: action)
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .scheduleItem(event):
			state.itemsQueue.append(event)
			return showItemIfPossible(state: &state)
		case .showNextItemIfPossible:
			return showItemIfPossible(state: &state)
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .hud(.delegate(.dismiss)):
			state.hud = nil
			return dismiss(&state)
		default:
			return .none
		}
	}

	private func showItemIfPossible(state: inout State) -> EffectTask<Action> {
		guard !state.itemsQueue.isEmpty else {
			return .none
		}

		if state.isPresenting {
			let presentedItem = state.itemsQueue[0]

			if case .hud = presentedItem {
				// A HUD is force dismissed when next item comes in, AKA it is a lower priority.
				state.hud = nil
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
			state.hud = .init(content: hud)
			return .none
		case let .alert(alert):
			state.alert = alert
			return setIsUserInteractionEnabled(&state, isEnabled: true)
		}
	}

	private func dismissAlert(state: inout State, withAction action: OverlayWindowClient.Item.AlertAction) -> EffectTask<Action> {
		let item = state.itemsQueue[0]
		if case let .alert(state) = item {
			overlayWindowClient.sendAlertAction(action, state.id)
		}

		return dismiss(&state)
	}

	private func dismiss(_ state: inout State) -> EffectTask<Action> {
		state.itemsQueue.removeFirst()
		return setIsUserInteractionEnabled(&state, isEnabled: false)
			.concatenate(with: showItemIfPossible(state: &state))
	}

	/// Sets the interaction enabled on the window, by implication this will also enable/disable the interaction
	/// with the main app window. When showing an Alert, we don't want users to be able to interact with the main app window for example.
	private func setIsUserInteractionEnabled(_ state: inout State, isEnabled: Bool) -> EffectTask<Action> {
		overlayWindowClient.setIsUserIteractionEnabled(isEnabled)
		return .none
	}
}
