import ComposableArchitecture
import SwiftUI

// MARK: - SignWithFactorSourcesOfKindLedger.View
extension SignWithFactorSourcesOfKindLedger {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SignWithFactorSourcesOfKindLedger>

		public init(store: StoreOf<SignWithFactorSourcesOfKindLedger>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			FactorSourceAccess.View(store: store.factorSourceAccess)
		}
	}
}

private extension StoreOf<SignWithFactorSourcesOfKindLedger> {
	var factorSourceAccess: StoreOf<FactorSourceAccess> {
		scope(state: \.factorSourceAccess, action: \.child.factorSourceAccess)
	}
}
