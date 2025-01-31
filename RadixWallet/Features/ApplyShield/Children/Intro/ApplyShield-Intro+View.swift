import SwiftUI

extension ApplyShield.Intro.State {
	var controlState: ControlState {
		hasEnoughXRD ? .enabled : .disabled
	}
}

// MARK: - ApplyShield.Intro.View
extension ApplyShield.Intro {
	struct View: SwiftUI.View {
		let store: StoreOf<ApplyShield.Intro>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .medium3) {
						Image(.applyShieldIntro)

						if let shieldName = store.shieldName {
							Text("\(shieldName.rawValue) Created")
								.textStyle(.sheetTitle)
						}

						Text("Apply this Shield to Accounts and Personas. You can update it any time.")
							.textStyle(.body1Link)
							.padding(.horizontal, .small2)
							.padding(.top, .small3)

						HStack(spacing: .small1) {
							Image(.info)
								.resizable()
								.frame(.smallest)
							Text("To apply your Shield on the Radix Network, you’ll need to sign a transaction")
								.textStyle(.body2HighImportance)
								.multilineTextAlignment(.leading)
								.flushedLeft
						}
						.foregroundStyle(.app.gray1)
						.embedInContainer
						.padding(.top, .small1)

						if !store.hasEnoughXRD {
							StatusMessageView(
								text: "Not enough XRD to pay transaction. Get some XRD tokens first to apply Shields.",
								type: .warning,
								useNarrowSpacing: true,
								useSmallerFontSize: true
							)
							.padding(.horizontal, .medium3)
							.padding(.top, .small2)
						}

						Spacer()
					}
					.foregroundStyle(.app.gray1)
					.multilineTextAlignment(.center)
					.padding([.horizontal, .bottom], .large2)
				}
				.footer {
					VStack(spacing: .medium2) {
						Button("Apply to Accounts and Personas") {
							self.store.send(.view(.startApplyingButtonTapped))
						}
						.buttonStyle(.primaryRectangular)
						.controlState(store.controlState)

						Button("Skip For Now") {
							store.send(.view(.skipButtonTapped))
						}
						.buttonStyle(.primaryText())
						.multilineTextAlignment(.center)
					}
				}
				.task {
					store.send(.view(.task))
				}
			}
		}
	}
}
