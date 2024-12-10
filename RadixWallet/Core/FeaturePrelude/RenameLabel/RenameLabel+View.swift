import SwiftUI

// MARK: - RenameLabel.View
extension RenameLabel {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<RenameLabel>
		@FocusState private var textFieldFocus: Bool

		var body: some SwiftUI.View {
			content
				.withNavigationBar {
					store.send(.view(.closeButtonTapped))
				}
				.presentationDetents([.fraction(0.55), .large])
				.presentationDragIndicator(.visible)
				.presentationBackground(.blur)
		}

		private var content: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .zero) {
					VStack(spacing: .medium1) {
						Text(L10n.LinkedConnectors.RenameConnector.title)
							.textStyle(.sheetTitle)
							.multilineTextAlignment(.center)

						Text(L10n.LinkedConnectors.RenameConnector.subtitle)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)

						AppTextField(
							placeholder: "",
							text: $store.label.sending(\.view.labelChanged),
							hint: store.hint,
							focus: .on(
								true,
								binding: $store.textFieldFocused.sending(\.view.focusChanged),
								to: $textFieldFocus
							)
						)
						.keyboardType(.asciiCapable)
						.autocorrectionDisabled()
					}
					.foregroundColor(.app.gray1)
					.padding(.horizontal, .medium3)

					Spacer()
				}
				.padding(.top, .small2)
				.padding(.horizontal, .medium3)
				.footer {
					WithControlRequirements(
						store.sanitizedLabel,
						forAction: { store.send(.view(.updateTapped($0))) }
					) { action in
						Button(L10n.LinkedConnectors.RenameConnector.update, action: action)
							.buttonStyle(.primaryRectangular)
							.controlState(store.controlState)
					}
				}
			}
		}
	}
}

private extension RenameLabel.State {
	var hint: Hint.ViewState? {
		switch status {
		case .empty:
			.iconError(L10n.LinkedConnectors.RenameConnector.errorEmpty)
		case .tooLong:
			.iconError(L10n.Error.AccountLabel.tooLong)
		case .valid:
			nil
		}
	}

	var controlState: ControlState {
		status == .valid ? .enabled : .disabled
	}
}
