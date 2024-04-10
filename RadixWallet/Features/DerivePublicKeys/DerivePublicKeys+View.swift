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
			FactorSourceAccess.View(store: store.factorSourceAccess)
		}
	}
}

private extension StoreOf<DerivePublicKeys> {
	var factorSourceAccess: StoreOf<FactorSourceAccess> {
		scope(state: \.factorSourceAccess, action: \.child.factorSourceAccess)
	}
}
