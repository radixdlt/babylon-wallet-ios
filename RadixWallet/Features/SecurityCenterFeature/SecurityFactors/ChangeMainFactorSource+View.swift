import SwiftUI

// MARK: - ChangeMainFactorSource.View
extension ChangeMainFactorSource {
	struct View: SwiftUI.View {
		let store: StoreOf<ChangeMainFactorSource>
		@Environment(\.dismiss) var dismiss

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .large2) {
						Text("Change Default Biometrics/PIN")
							.textStyle(.sheetTitle)
							.padding(.horizontal, .medium3)

						Text("Select the biometrics/PIN factor that will be automatically selected when you create a new Account or Persona.")
							.textStyle(.body1Regular)
							.padding(.horizontal, .medium3)

						VStack(spacing: .medium3) {
							ForEachStatic(store.factorSources) { factorSource in
								card(factorSource)
							}
						}

						Spacer()
					}
					.foregroundStyle(.app.gray1)
					.multilineTextAlignment(.center)
					.padding(.horizontal, .medium3)
				}
				.footer {
					WithControlRequirements(
						store.selected,
						forAction: { store.send(.view(.continueButtonTapped($0))) }
					) { action in
						Button(L10n.Common.continue, action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
				.task {
					store.send(.view(.task))
				}
				.withNavigationBar {
					dismiss()
				}
			}
		}

		private func card(_ factorSource: FactorSource) -> some SwiftUI.View {
			WithPerceptionTracking {
				FactorSourceCard(
					kind: .instance(
						factorSource: factorSource,
						kind: .short(showDetails: false)
					),
					mode: .selection(type: .radioButton, isSelected: store.selected == factorSource)
				)
				.onTapGesture {
					store.send(.view(.selected(factorSource)))
				}
			}
		}
	}
}
