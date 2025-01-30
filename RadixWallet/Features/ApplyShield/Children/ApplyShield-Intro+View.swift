import SwiftUI

extension ApplyShield.Intro {
	struct View: SwiftUI.View {
		let store: StoreOf<ApplyShield.Intro>
		@Environment(\.dismiss) var dismiss

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .large2) {
						Image(.addShieldBuilderSeedingFactorsIntro)

						if let shieldName = store.shieldName {
							Text("\(shieldName.rawValue) Created")
								.textStyle(.sheetTitle)
						}

						Text("Apply this Shield to Accounts and Personas. You can update it any time.")
							.textStyle(.body1Link)
							.padding(.horizontal, .small2)

						Spacer()
					}
					.foregroundStyle(.app.gray1)
					.multilineTextAlignment(.center)
					.padding(.horizontal, .large2)
				}
				.footer {
					VStack(spacing: .medium2) {
						Button("Apply to Accounts and Personas") {
							self.store.send(.view(.startApplyingButtonTapped))
						}
						.buttonStyle(.primaryRectangular)
						//                        .controlState(store.controlState)

						Button("Skip For Now") {
							store.send(.view(.skipButtonTapped))
						}
						.buttonStyle(.primaryText())
						.multilineTextAlignment(.center)
					}
				}
				.withNavigationBar {
					dismiss()
				}
				.task {
					store.send(.view(.task))
				}
			}
		}
	}
}
