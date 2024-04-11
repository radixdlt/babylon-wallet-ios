import SwiftUI

// MARK: - ImportOlympiaNameLedgerAndDerivePublicKeys.View
extension ImportOlympiaNameLedgerAndDerivePublicKeys {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ImportOlympiaNameLedgerAndDerivePublicKeys>

		public init(store: StoreOf<ImportOlympiaNameLedgerAndDerivePublicKeys>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithNavigationBar {
				store.send(.view(.closeButtonTapped))
			} content: {
				IfLetStore(store.scope(state: \.nameLedger, action: { .child(.nameLedger($0)) })) { childStore in
					NameLedgerFactorSource.View(store: childStore)
				} else: {
					Rectangle()
						.fill(.clear)
				}
				.navigationDestination(
					store: store.scope(state: \.$derivePublicKeys, action: { .child(.derivePublicKeys($0)) })
				) {
					DerivePublicKeys.View(store: $0)
						.navigationBarBackButtonHidden()
				}
			}
		}
	}
}
