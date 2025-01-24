import SwiftUI

// MARK: - Signing.View
extension Signing {
	struct View: SwiftUI.View {
		let store: StoreOf<Signing>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				FactorSourceAccess.View(store: store.factorSourceAccess)
			}
		}
	}
}

private extension StoreOf<Signing> {
	var factorSourceAccess: StoreOf<FactorSourceAccess> {
		scope(state: \.factorSourceAccess, action: \.child.factorSourceAccess)
	}
}
