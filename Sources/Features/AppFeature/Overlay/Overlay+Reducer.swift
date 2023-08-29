import FeaturePrelude
import OverlayWindowClient
import SwiftUI

struct OverlayReducer: Sendable, FeatureReducer {
	struct State: Hashable, Sendable {
		var itemsQueue: OrderedSet<OverlayWindowClient.Item> = []
		/// A HUD can be shown on top of any other item that is presented.
		/// Maybe this will be extented in the future to support other kinds of items.
		var hudItemsQueue: OrderedSet<OverlayWindowClient.Item.HUD> = []

		var isPresenting: Bool {
			destination != nil
		}

		@PresentationState
		public var destination: Destinations.State?

		@PresentationState
		public var hud: HUD.State?
	}

	enum ViewAction: Sendable, Equatable {
		case task
	}

	enum InternalAction: Sendable, Equatable {
		case scheduleItem(OverlayWindowClient.Item)
		case showHUDIfAvailable
	}

	enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
		case hud(PresentationAction<HUD.Action>)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case alert(OverlayWindowClient.Item.AlertState)
			case dappInteractionSuccess(DappInteractionSuccess.State)
			case transactionPoll(TransactionStatusPolling.State)
		}

		public enum Action: Sendable, Equatable {
			case alert(OverlayWindowClient.Item.AlertAction)
			case dappInteractionSuccess(DappInteractionSuccess.Action)
			case transactionPoll(TransactionStatusPolling.Action)
		}

		public var body: some ReducerProtocol<State, Action> {
			Scope(state: /State.dappInteractionSuccess, action: /Action.dappInteractionSuccess) {
				DappInteractionSuccess()
			}

			Scope(state: /State.transactionPoll, action: /Action.transactionPoll) {
				TransactionStatusPolling()
			}
		}
	}

	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.continuousClock) var clock

	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
			.ifLet(\.$hud, action: /Action.child .. ChildAction.hud) {
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
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .scheduleItem(.hud(item)):
			state.hudItemsQueue.append(item)
			if state.hud == nil {
				return showHUDItemIfAvailable(state: &state)
			}

			// A HUD is force dismissed when next item comes in, AKA it is a lower priority.
			state.hud = nil
			state.hudItemsQueue.removeFirst()
			return .run { send in
				// Hacky - A very minor delay is needed before showing the next item is a HUD.
				try await clock.sleep(for: .milliseconds(100))
				await send(.internal(.showHUDIfAvailable))
			}

		case let .scheduleItem(item):
			state.itemsQueue.append(item)
			return showItemIfPossible(state: &state)

		case .showHUDIfAvailable:
			return showHUDItemIfAvailable(state: &state)
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .destination(.dismiss):
			return dismissItem(&state)

		case let .destination(.presented(.alert(action))):
			if let item = state.itemsQueue.first, case let .alert(state) = item {
				overlayWindowClient.sendAlertAction(action, state.id)
			}
			return .none

		case .hud(.presented(.delegate(.dismiss))):
			return dismissHUD(&state)

		case .hud(.dismiss):
			return dismissHUD(&state)

		default:
			return .none
		}
	}

	private func showItemIfPossible(state: inout State) -> EffectTask<Action> {
		guard !state.itemsQueue.isEmpty, !state.isPresenting else {
			return .none
		}

		guard !state.isPresenting else {
			return .none
		}

		let nextItem = state.itemsQueue[0]

		switch nextItem {
		case let .alert(alert):
			state.destination = .alert(alert)
			return setIsUserInteractionEnabled(&state, isEnabled: true)
		case let .dappInteractionSucess(item):
			state.destination = .dappInteractionSuccess(.init(item: item))
			return setIsUserInteractionEnabled(&state, isEnabled: true)
		case let .transactionPoll(item):
			state.destination = .transactionPoll(.init(txID: item.txID, disableInProgressDismissal: item.disableInProgressDismissal))
			return setIsUserInteractionEnabled(&state, isEnabled: true)
		case .hud:
			// Handled separately
			return .none
		}
	}

	private func showHUDItemIfAvailable(state: inout State) -> EffectTask<Action> {
		guard !state.hudItemsQueue.isEmpty else {
			return .none
		}

		state.hud = .init(content: state.hudItemsQueue[0])
		return .none
	}

	private func dismissAlert(state: inout State, withAction action: OverlayWindowClient.Item.AlertAction) -> EffectTask<Action> {
		let item = state.itemsQueue[0]
		if case let .alert(state) = item {
			overlayWindowClient.sendAlertAction(action, state.id)
		}

		return dismissItem(&state)
	}

	private func dismissItem(_ state: inout State) -> EffectTask<Action> {
		state.destination = nil
		state.itemsQueue.removeFirst()
		return setIsUserInteractionEnabled(&state, isEnabled: false)
			.concatenate(with: showItemIfPossible(state: &state))
	}

	private func dismissHUD(_ state: inout State) -> EffectTask<Action> {
		state.hud = nil
		state.hudItemsQueue.removeFirst()
		return showHUDItemIfAvailable(state: &state)
	}

	/// Sets the interaction enabled on the window, by implication this will also enable/disable the interaction
	/// with the main app window. When showing an Alert, we don't want users to be able to interact with the main app window for example.
	private func setIsUserInteractionEnabled(_ state: inout State, isEnabled: Bool) -> EffectTask<Action> {
		overlayWindowClient.setIsUserIteractionEnabled(isEnabled)
		return .none
	}
}
