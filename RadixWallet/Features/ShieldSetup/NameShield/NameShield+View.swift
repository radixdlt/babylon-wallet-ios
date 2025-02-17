extension NameShield.State {
	var hint: Hint.ViewState? {
		guard let sanitizedName, sanitizedName.count > DisplayName.maxLength else { return nil }
		return .iconError(L10n.ShieldWizardName.tooLong)
	}

	var controlState: ControlState {
		sanitizedName != nil && hint == nil ? .enabled : .disabled
	}
}

// MARK: - NameShield.View
extension NameShield {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<NameShield>
		@FocusState private var textFieldFocus: Bool

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .small1) {
						Text(L10n.ShieldWizardName.title)
							.textStyle(.sheetTitle)
							.multilineTextAlignment(.center)

						Text(L10n.ShieldWizardName.subtitle)
							.textStyle(.body1Link)
							.multilineTextAlignment(.center)

						AppTextField(
							placeholder: "",
							text: $store.inputtedName.sending(\.view.textFieldChanged),
							hint: store.hint,
							focus: .on(
								true,
								binding: $store.textFieldFocused.sending(\.view.focusChanged),
								to: $textFieldFocus
							)
						)
						.keyboardType(.asciiCapable)
						.autocorrectionDisabled()
						.padding(.top, .huge2)
					}
					.foregroundStyle(.app.gray1)
					.padding(.horizontal, .medium3)
				}
				.footer {
					WithControlRequirements(
						store.sanitizedName,
						forAction: { store.send(.view(.confirmButtonTapped($0))) }
					) { action in
						Button(L10n.Common.confirm, action: action)
							.buttonStyle(.primaryRectangular)
							.controlState(store.controlState)
					}
				}
			}
		}
	}
}
