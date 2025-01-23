import SwiftUI

// MARK: - DerivePublicKeys.View
extension DerivePublicKeys {
	struct View: SwiftUI.View {
		let store: StoreOf<DerivePublicKeys>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				if let child = store.scope(state: \.factorSourceAccess, action: \.child.factorSourceAccess) {
					NewFactorSourceAccess.View(store: child)
				} else {
					// We don't need the FactorSourceAccess, so we can start the derivation right away
					Rectangle()
						.presentationDetents([.height(1)])
						.presentationDragIndicator(.hidden)
						.onFirstTask { @MainActor in
							store.send(.internal(.deriveWithSpecificPrivateHD__MustImplement))
						}
				}
			}
		}
	}
}
