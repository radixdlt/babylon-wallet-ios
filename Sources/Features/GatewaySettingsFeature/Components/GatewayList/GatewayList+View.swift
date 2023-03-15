import FeaturePrelude

// MARK: - GatewayList.View
extension GatewayList {
	public struct ViewState: Equatable {}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<GatewayList>

		public init(store: StoreOf<GatewayList>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			LazyVStack(spacing: .zero) {
				ForEachStore(
					store.scope(
						state: \.gateways,
						action: { .child(.gateway(id: $0, action: $1)) }
					),
					content: {
						GatewayRow.View(store: $0)
						Separator()
							.padding(.horizontal, .medium3)
					}
				)
			}
			.buttonStyle(.tappableRowStyle)
			.onAppear {
				ViewStore(store.stateless).send(.view(.appeared))
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - GatewayList_Preview
struct GatewayList_Preview: PreviewProvider {
	static var previews: some View {
		GatewayList.View(
			store: .init(
				initialState: .previewValue,
				reducer: GatewayList()
			)
		)
	}
}

extension GatewayList.State {
	static let previewValue = Self(
		gateways: .init(uniqueElements: [
			.previewValue1, .previewValue2, .previewValue3,
		]))
}
#endif
