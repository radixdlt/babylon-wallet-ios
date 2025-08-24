import SwiftUI

// MARK: - ArculusForgotPIN-EnterNewPIN.View
extension ArculusForgotPIN.EnterNewPIN {
	struct View: SwiftUI.View {
		let store: StoreOf<ArculusForgotPIN.EnterNewPIN>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ArculusCreatePIN.View(store: store.scope(state: \.createPIN, action: \.child.createPIN))
			}
		}
	}
}
