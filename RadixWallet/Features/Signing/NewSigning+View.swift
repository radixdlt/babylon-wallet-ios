import SwiftUI

// MARK: - NewSigning.View
extension NewSigning {
	struct View: SwiftUI.View {
		let store: StoreOf<NewSigning>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				/// We set the `.id` to the `factorSourceId` so that, when multiple factor sources are required, each of them has its own view created.
				/// Otherwise, only the first of them would have the `.onFirstTask()` triggered, and the logic for the remaining ones
				/// wouldn't be performed.
				FactorSourceAccess.View(store: store.factorSourceAccess)
					.id(store.input.factorSourceId)
			}
		}
	}
}

private extension StoreOf<NewSigning> {
	var factorSourceAccess: StoreOf<FactorSourceAccess> {
		scope(state: \.factorSourceAccess, action: \.child.factorSourceAccess)
	}
}
