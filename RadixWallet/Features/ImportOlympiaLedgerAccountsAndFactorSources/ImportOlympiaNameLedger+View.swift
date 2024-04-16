import SwiftUI

// MARK: - ImportOlympiaNameLedger.View
extension ImportOlympiaNameLedger {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ImportOlympiaNameLedger>

		public init(store: StoreOf<ImportOlympiaNameLedger>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithNavigationBar {
				store.send(.view(.closeButtonTapped))
			} content: {
				NameLedgerFactorSource.View(store: store.scope(state: \.nameLedger, action: \.child.nameLedger))
			}
		}
	}
}
