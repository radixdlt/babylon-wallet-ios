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
						hint: store.hint,
						preventScreenshot: false
					)
					.keyboardType(.asciiCapable)
					.autocorrectionDisabled()

					Button(L10n.Common.confirm) {
						store.send(.view(.confirmButtonTapped))
					}
					.buttonStyle(.primaryRectangular)
					.controlState(store.controlState)
				}
				.multilineTextAlignment(.leading)
			}
		}
	}
}

private extension PasswordFactorSourceAccess.State {
	var controlState: ControlState {
		input.isEmpty || showError ? .disabled : .enabled
	}

	var hint: Hint.ViewState? {
		showError ? Hint.ViewState.iconError(L10n.FactorSourceActions.Password.incorrect) : nil
	}
}
