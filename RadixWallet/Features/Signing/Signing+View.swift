import SwiftUI

// MARK: - Signing.View
extension Signing {
	struct View: SwiftUI.View {
		let store: StoreOf<Signing>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				NewFactorSourceAccess.View(store: store.factorSourceAccess)
			}
		}
	}
}

private extension StoreOf<Signing> {
	var factorSourceAccess: StoreOf<NewFactorSourceAccess> {
		scope(state: \.factorSourceAccess, action: \.child.factorSourceAccess)
	}
}
