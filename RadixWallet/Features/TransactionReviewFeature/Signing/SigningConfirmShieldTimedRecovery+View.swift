import SwiftUI

// MARK: - SigningConfirmShieldTimedRecovery.View
extension SigningConfirmShieldTimedRecovery {
	struct View: SwiftUI.View {
		let store: StoreOf<SigningConfirmShieldTimedRecovery>
		@Environment(\.dismiss) var dismiss

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(alignment: .center, spacing: .medium1) {
						CloseButton {
							dismiss()
						}
						.flushedRight
						Text("Cannot Update Shield Yet")
							.textStyle(.sheetTitle)
							.foregroundStyle(.primaryText)
							.multilineTextAlignment(.center)

						Text("You can use your timed emergency fallback to confirm Shield update or you can restart the signing process.")
							.textStyle(.body1HighImportance)
							.foregroundStyle(.primaryText)
							.multilineTextAlignment(.center)

						emergencyFallbackView
					}
				}
				.padding(.medium3)
				.footer {
					VStack {
						Button("Use Emergency Fallback") {
							store.send(.view(.useEmergencyFallbackButtonTapped))
						}
						.buttonStyle(.primaryRectangular(isDestructive: true))

						Button("Restart Signing") {
							store.send(.view(.restartSigningButtonTapped))
						}
						.buttonStyle(.primaryRectangular)
					}
				}
			}
		}
	}
}

extension SigningConfirmShieldTimedRecovery.View {
	private var emergencyFallbackView: some SwiftUI.View {
		VStack(spacing: .zero) {
			HStack {
				Text(L10n.ShieldWizardRecovery.Fallback.title)
					.textStyle(.body1Header)

				Spacer()

				Button {
					store.send(.view(.fallbackInfoButtonTapped))
				} label: {
					Image(.info)
						.resizable()
						.frame(.smallest)
				}
			}
			.padding(.horizontal, .medium3)
			.padding(.vertical, .small1)
			.foregroundStyle(.white)
			.background(.error)

			VStack(spacing: .medium2) {
				Text("Starts the Shield update process. Requires a confirmation transaction when wait period is over.")
					.textStyle(.body2Regular)
					.foregroundStyle(.primaryText)
					.flushedLeft

				Text("You can confirm in")
					.textStyle(.body2HighImportance)
					.foregroundStyle(.error)
					.flushedLeft

				Label(store.periodUntilAutoConfirm.title, asset: AssetResource.emergencyFallbackCalendar)
					.textStyle(.body1Header)
					.foregroundStyle(.primaryText)
					.flushedLeft
					.padding(.horizontal, .medium3)
					.padding(.vertical, .small1)
					.background(.primaryBackground)
					.roundedCorners(radius: .small2)
					.cardShadow
			}
			.padding([.horizontal, .bottom], .medium3)
			.padding(.top, .medium3)
			.background(.lightError)
		}
		.frame(maxWidth: .infinity)
		.roundedCorners(radius: .small1)
	}
}
