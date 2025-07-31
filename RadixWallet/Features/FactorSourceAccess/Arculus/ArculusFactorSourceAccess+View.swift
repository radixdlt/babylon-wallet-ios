import SwiftUI

// MARK: - ArculusFactorSourceAccess.View
extension ArculusFactorSourceAccess {
	struct View: SwiftUI.View {
		let store: StoreOf<ArculusFactorSourceAccess>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack {
					ArculusPINInput.View(store: store.scope(state: \.pinInput, action: \.child.pinInput))
					WithControlRequirements(store.pinInput.validatedPin, forAction: { store.send(.view(.pinAdded($0))) }) { action in
						Button(L10n.Common.confirm, action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
			}
		}
	}
}
