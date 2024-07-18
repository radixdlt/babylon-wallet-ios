import ComposableArchitecture
import SwiftUI

// MARK: - GatewayList.View
extension GatewayList {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<GatewayList>

		public init(store: StoreOf<GatewayList>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				LazyVStack(spacing: .zero) {
					ForEachStore(
						store.scope(
							state: \.gateways,
							action: { .child(.gateway(id: $0, action: $1)) }
						),
						content: { store in
							VStack(spacing: .zero) {
								GatewayRow.View(store: store)

								if store.gateway.id != viewStore.gateways.last?.gateway.id {
									Separator()
										.padding(.horizontal, .medium3)
								} else {
									Separator()
								}
							}
							.background(Color.app.white)
						}
					)
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
