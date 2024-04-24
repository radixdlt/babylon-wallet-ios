import ComposableArchitecture
import SwiftUI

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
			AddressDetailView(address: viewStore.address) {
				viewStore.send(.closeButtonTapped)
			}
		}
	}
}
