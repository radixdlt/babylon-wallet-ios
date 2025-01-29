import SwiftUI

// MARK: - PasswordFactorSourceAccess.View
extension PasswordFactorSourceAccess {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<PasswordFactorSourceAccess>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .medium3) {
					AppTextField(
						useSecureField: true,
						primaryHeading: .init(text: "Password"),
						placeholder: "",
						text: $store.input.sending(\.view.inputChanged),
						hint: nil,
						preventScreenshot: false
					)

					Button(L10n.Common.confirm) {
						store.send(.view(.confirmButtonTapped))
					}
				}
			}
		}
	}
}
