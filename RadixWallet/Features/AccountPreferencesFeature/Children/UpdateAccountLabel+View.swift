import ComposableArchitecture
import SwiftUI

extension UpdateAccountLabel.State {
	var viewState: UpdateAccountLabel.ViewState {
		let (controlState, hint) = hintAndControlState
		return .init(
			accountLabel: accountLabel,
			sanitizedName: sanitizedName,
			updateButtonControlState: controlState,
			hint: hint,
			textFieldFocused: textFieldFocused
		)
	}

	private var hintAndControlState: (ControlState, Hint.ViewState?) {
		if let sanitizedName {
			if sanitizedName.count > Account.nameMaxLength {
				return (.disabled, .iconError(L10n.Error.AccountLabel.tooLong))
			}
		} else {
			return (.disabled, .iconError(L10n.Error.AccountLabel.missing))
		}

		return (.enabled, nil)
	}
}

extension UpdateAccountLabel {
	public struct ViewState: Equatable {
		let accountLabel: String
		let sanitizedName: NonEmptyString?
		let updateButtonControlState: ControlState
		let hint: Hint.ViewState?
		let textFieldFocused: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<UpdateAccountLabel>
		@Environment(\.dismiss) var dismiss
		@FocusState private var textFieldFocus: Bool

		init(store: StoreOf<UpdateAccountLabel>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			content
				.withNavigationBar {
					dismiss()
				}
				.presentationDetents([.fraction(0.55)])
				.presentationDragIndicator(.visible)
				.presentationBackground(.blur)
		}

		private var content: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .zero) {
					VStack(spacing: .medium1) {
						Text(L10n.AccountSettings.RenameAccount.title)
							.textStyle(.sheetTitle)
							.multilineTextAlignment(.center)

						Text(L10n.AccountSettings.RenameAccount.subtitle)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)

						let nameBinding = viewStore.binding(
							get: \.accountLabel,
							send: { .accountLabelChanged($0) }
						)
						AppTextField(
							placeholder: "",
							text: nameBinding,
							hint: viewStore.hint,
							focus: .on(
								true,
								binding: viewStore.binding(
									get: \.textFieldFocused,
									send: { .focusChanged($0) }
								),
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
						viewStore.sanitizedName,
						forAction: { viewStore.send(.updateTapped($0)) }
					) { action in
						Button(L10n.AccountSettings.SpecificAssetsDeposits.update, action: action)
							.buttonStyle(.primaryRectangular)
							.controlState(viewStore.updateButtonControlState)
					}
				}
			}
		}
	}
}
