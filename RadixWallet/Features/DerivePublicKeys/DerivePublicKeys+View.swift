import SwiftUI

// MARK: - DerivePublicKeys.View
extension DerivePublicKeys {
	struct View: SwiftUI.View {
		let store: StoreOf<DerivePublicKeys>

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

private extension StoreOf<DerivePublicKeys> {
	var factorSourceAccess: StoreOf<FactorSourceAccess> {
		scope(state: \.factorSourceAccess, action: \.child.factorSourceAccess)
	}
}
