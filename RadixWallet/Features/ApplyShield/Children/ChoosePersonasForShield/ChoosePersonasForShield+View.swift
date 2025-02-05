import ComposableArchitecture
import SwiftUI

// MARK: - ChoosePersonasForShield.View
extension ChoosePersonasForShield {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<ChoosePersonasForShield>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .medium2) {
						Text("Choose Personas")
							.lineSpacing(0)
							.textStyle(.sheetTitle)

						Text("Choose the Personas you want to apply this Shield to.")
							.textStyle(.body1HighImportance)

						ChoosePersonas.View(store: store.choosePersonas)
					}
					.padding(.horizontal, .medium1)
					.padding(.bottom, .medium2)
					.multilineTextAlignment(.center)
					.foregroundStyle(.app.gray1)
				}
				.footer {
					VStack(spacing: .medium3) {
						WithControlRequirements(
							store.choosePersonas.selectedPersonas,
							forAction: { store.send(.view(.continueButtonTapped($0))) }
						) { action in
							Button(L10n.Common.continue, action: {
								store.send(.view(.continueButtonTapped([])))
							})
							.buttonStyle(.primaryRectangular)
						}

						if store.canBeSkipped {
							Button("Skip") {
								store.send(.view(.skipButtonTapped))
							}
							.buttonStyle(.primaryText())
						}
					}
				}
			}
		}
	}
}

private extension StoreOf<ChoosePersonasForShield> {
	var choosePersonas: StoreOf<ChoosePersonas> {
		scope(state: \.choosePersonas, action: \.child.choosePersonas)
	}
}
