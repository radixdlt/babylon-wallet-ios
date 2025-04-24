import SwiftUI

// MARK: - SpotCheck.View
extension SpotCheck {
	struct View: SwiftUI.View {
		let store: StoreOf<SpotCheck>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				FactorSourceAccess.View(store: store.factorSourceAccess)
			}
		}
	}
}

private extension StoreOf<SpotCheck> {
	var factorSourceAccess: StoreOf<FactorSourceAccess> {
		scope(state: \.factorSourceAccess, action: \.child.factorSourceAccess)
	}
}
