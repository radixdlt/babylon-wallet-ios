import SwiftUI

// MARK: - PasswordFactorSourceAccess.View
extension PasswordFactorSourceAccess {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<PasswordFactorSourceAccess>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .medium3) {
					AppTextField(
						useSecureField: store.useSecureField,
						primaryHeading: .init(text: "Password"),
						placeholder: "",
						text: $store.input.sending(\.view.inputChanged),
						hint: nil,
						preventScreenshot: false,
						innerAccessory: { visibility }
					)
					.keyboardType(.asciiCapable)
					.autocorrectionDisabled()

					Button(L10n.Common.confirm) {
						store.send(.view(.confirmButtonTapped))
					}
					.buttonStyle(.primaryRectangular)
				}
				.multilineTextAlignment(.leading)
			}
		}

		private var visibility: some SwiftUI.View {
			Image(store.useSecureField ? .homeAggregatedValueHidden : .homeAggregatedValueShown)
				.onTapGesture {
					store.send(.view(.visibilityToggled))
				}
		}
	}
}
