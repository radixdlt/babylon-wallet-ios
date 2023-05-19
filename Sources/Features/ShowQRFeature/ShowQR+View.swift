import FeaturePrelude

// MARK: - ShowQR.View
extension ShowQR {
	@MainActor
	public struct View: SwiftUI.View {
		let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

// MARK: - Body

extension ShowQR.View {
	public var body: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
			VStack(spacing: 0) {
				HStack {
					Spacer()
					CloseButton {
						viewStore.send(.closeeButtonTapped)
					}
				}
				AccountAddressQRCodePanel(address: viewStore.address)
			}
		}
	}
}
