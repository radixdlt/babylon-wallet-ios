import SwiftUI

// MARK: - ImportOlympiaNameLedger.View
extension ImportOlympiaNameLedger {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<ImportOlympiaNameLedger>

		init(store: StoreOf<ImportOlympiaNameLedger>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithNavigationBar {
				store.send(.view(.closeButtonTapped))
			} content: {
				NameLedgerFactorSource.View(store: store.scope(state: \.nameLedger, action: \.child.nameLedger))
			}
		}
	}
}
