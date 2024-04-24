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
		// TODO: Remove this view and call directly AddressDetailView
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
			AddressDetailView(address: .account(viewStore.accountAddress, isLedgerHWAccount: false)) {
				viewStore.send(.closeButtonTapped)
			}
		}
	}
}
