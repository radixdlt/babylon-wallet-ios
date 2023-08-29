import ComposableArchitecture
import FeaturePrelude
import OverlayWindowClient
import SwiftUI

// MARK: - OverlayReducer.View
extension OverlayReducer {
	struct View: SwiftUI.View {
		private let store: StoreOf<OverlayReducer>

		public init(store: StoreOf<OverlayReducer>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				IfLetStore(store.scope(state: \.$hud, action: { .child(.hud($0)) })) {
					HUD.View(store: $0)
				}
				.alert(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /OverlayReducer.Destinations.State.alert,
					action: OverlayReducer.Destinations.Action.alert
				)
				.sheet(store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
				       state: /OverlayReducer.Destinations.State.dappInteractionSuccess,
				       action: OverlayReducer.Destinations.Action.dappInteractionSuccess,
				       content: { store in
				       	DappInteractionSuccess.View(store: store)
				       })
				.sheet(store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
				       state: /OverlayReducer.Destinations.State.transactionPoll,
				       action: OverlayReducer.Destinations.Action.transactionPoll,
				       content: { store in
				       	TransactionStatusPolling.View(store: store)
				       })
				.task { viewStore.send(.task) }
			}
		}
	}
}
