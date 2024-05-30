import ComposableArchitecture
import SwiftUI

// MARK: - DerivePublicKeys.View
extension DerivePublicKeys {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<DerivePublicKeys>

		public init(store: StoreOf<DerivePublicKeys>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			IfLetStore(store.scope(state: \.factorSourceAccess, action: \.child.factorSourceAccess)) {
				FactorSourceAccess.View(store: $0)
			} else: {
				// We don't need the FactorSourceAccess, so we can start the derivation right away
				Rectangle()
					.presentationDetents([.height(1)])
					.presentationDragIndicator(.hidden)
					.onFirstTask { @MainActor in
						store.send(.internal(.start))
					}
			}
		}
	}
}
