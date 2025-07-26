import SwiftUI

// MARK: - ArculusFactorSourceAccess.View
extension ArculusFactorSourceAccess {
	struct View: SwiftUI.View {
		let store: StoreOf<ArculusFactorSourceAccess>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				// TODO: implement
				Text("Implement: ArculusFactorSourceAccess")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { store.send(.view(.appeared)) }
			}
		}
	}
}
