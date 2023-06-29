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
				IfLetStore(
					store.scope(
						state: \.hud,
						action: { .child(.hud($0)) }
					),
					then: { HUD.View(store: $0) }
				)
				.task { viewStore.send(.task) }
				.alert(store: store.scope(state: \.$alert, action: { .view(.alert($0)) }))
			}
		}
	}
}
