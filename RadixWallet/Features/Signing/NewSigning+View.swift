import SwiftUI

// MARK: - NewSigning.View
extension NewSigning {
	struct View: SwiftUI.View {
		let store: StoreOf<NewSigning>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				NewFactorSourceAccess.View(store: store.factorSourceAccess)
			}
		}
	}
}

private extension StoreOf<NewSigning> {
	var factorSourceAccess: StoreOf<NewFactorSourceAccess> {
		scope(state: \.factorSourceAccess, action: \.child.factorSourceAccess)
	}
}
