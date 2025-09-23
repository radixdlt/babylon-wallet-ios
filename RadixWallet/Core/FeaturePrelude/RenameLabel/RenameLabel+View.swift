import SwiftUI

// MARK: - RenameLabel.View
extension RenameLabel {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<RenameLabel>
		@FocusState private var textFieldFocus: Bool

		var body: some SwiftUI.View {
			content
				.background(Color.primaryBackground)
				.withNavigationBar {
					store.send(.view(.closeButtonTapped))
				}
				.presentationDetents([.fraction(0.6), .large])
				.presentationDragIndicator(.visible)
				.presentationBackground(.blur)
		}

		private var content: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .zero) {
					VStack(spacing: .medium1) {
						Text(store.kind.title)
							.textStyle(.sheetTitle)
							.multilineTextAlignment(.center)

						Text(store.kind.subtitle)
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
					.foregroundColor(Color.primaryText)
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
						Button(L10n.RenameLabel.update, action: action)
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
			.iconError(kind.empty)
		case .tooLong:
			.iconError(kind.tooLong)
		case .valid:
			nil
		}
	}

	var controlState: ControlState {
		status == .valid ? .enabled : .disabled
	}
}

private extension RenameLabel.State.Kind {
	var title: String {
		switch self {
		case .account: L10n.RenameLabel.Account.title
		case .connector: L10n.RenameLabel.Connector.title
		case .factorSource: L10n.RenameLabel.FactorSource.title
		case .shield:
			"Rename Shield"
		}
	}

	var subtitle: String {
		switch self {
		case .account: L10n.RenameLabel.Account.subtitle
		case .connector: L10n.RenameLabel.Connector.subtitle
		case .factorSource: L10n.RenameLabel.FactorSource.subtitle
		case .shield: ""
		}
	}

	var empty: String {
		switch self {
		case .account: L10n.RenameLabel.Account.empty
		case .connector: L10n.RenameLabel.Connector.empty
		case .factorSource: L10n.RenameLabel.FactorSource.empty
		case .shield: ""
		}
	}

	var tooLong: String {
		switch self {
		case .account: L10n.RenameLabel.Account.tooLong
		case .connector: ""
		case .factorSource: L10n.RenameLabel.FactorSource.tooLong
		case .shield: ""
		}
	}
}
