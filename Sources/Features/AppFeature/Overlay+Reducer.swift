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

		let window: UIWindow
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
	}

	enum ChildAction: Sendable, Equatable {
		case hud(HUD.Action)
	}

	@Dependency(\.overlayWindowClient) var overlayWindowClient

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
			return showEventIfPossible(state: &state)
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

	/// Sets the interaction enabled on the window, by implication this will also enable/disable the interaction
	/// with the main app window. When showing an Alert, we don't want users to be able to interact with the main app window for example.
	private func setIsUserInteractionEnabled(_ state: inout State, isEnabled: Bool) -> EffectTask<Action> {
		Task { @MainActor [window = state.window] in
			window.isUserInteractionEnabled = isEnabled
		}
		return .none
	}

	private func dismiss(_ state: inout State) -> EffectTask<Action> {
		state.itemsQueue.removeFirst()
		return setIsUserInteractionEnabled(&state, isEnabled: false)
			.concatenate(with: showEventIfPossible(state: &state))
	}

	private func showEventIfPossible(state: inout State) -> EffectTask<Action> {
		guard !state.isPresenting, !state.itemsQueue.isEmpty else {
			return .none
		}

		let event = state.itemsQueue[0]

		switch event {
		case let .hud(hud):
			state.hud = .init(content: hud)
			return .none
		case let .alert(alert):
			state.alert = alert
			return setIsUserInteractionEnabled(&state, isEnabled: true)
		}
	}

	private func dismissAlert(state: inout State, withAction action: OverlayWindowClient.Item.AlertAction) -> EffectTask<Action> {
		let event = state.itemsQueue[0]
		if case let .alert(state) = event {
			overlayWindowClient.sendAlertAction(action, state.id)
		}

		return dismiss(&state)
	}
}
