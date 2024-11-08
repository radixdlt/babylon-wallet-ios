import ComposableArchitecture
import SwiftUI

// MARK: - GatewayList.View
extension GatewayList {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<GatewayList>

		init(store: StoreOf<GatewayList>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				LazyVStack(spacing: .zero) {
					ForEachStore(store.scope(state: \.gateways, action: \.child.gateway)) { rowStore in
						VStack(spacing: .zero) {
							GatewayRow.View(store: rowStore)

							let isLastRow = rowStore.gateway.id == store.gateways.last?.gateway.id
							Separator()
								.padding(.horizontal, isLastRow ? 0 : .medium3)
						}
						.background(.app.white)
					}
				}
				.buttonStyle(.tappableRowStyle)
				.onAppear {
					store.send(.view(.appeared))
				}
			}
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

// MARK: - GatewayList_Preview
struct GatewayList_Preview: PreviewProvider {
	static var previews: some View {
		GatewayList.View(
			store: .init(
				initialState: .previewValue,
				reducer: GatewayList.init
			)
		)
	}
}

extension GatewayList.State {
	static let previewValue = Self(
		gateways: [
			.previewValue1, .previewValue2, .previewValue3,
		].asIdentified()
	)
}
#endif
