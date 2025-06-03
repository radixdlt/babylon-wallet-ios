import SwiftUI

// MARK: - Authorization.View
extension Authorization {
	struct View: SwiftUI.View {
		let store: StoreOf<Authorization>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ZStack {
					Color.primaryBackground
					FactorSourceAccess.View(store: store.factorSourceAccess)
				}
			}
		}
	}
}

private extension StoreOf<Authorization> {
	var factorSourceAccess: StoreOf<FactorSourceAccess> {
		scope(state: \.factorSourceAccess, action: \.child.factorSourceAccess)
	}
}
