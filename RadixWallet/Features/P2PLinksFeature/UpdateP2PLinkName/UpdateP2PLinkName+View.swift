import SwiftUI

extension UpdateP2PLinkName.State {
	var viewState: UpdateP2PLinkName.ViewState {
		let (controlState, hint) = hintAndControlState
		return .init(
			linkName: linkName,
			sanitizedName: sanitizedName,
			updateButtonControlState: controlState,
			hint: hint,
			textFieldFocused: textFieldFocused
		)
	}

	private var hintAndControlState: (ControlState, Hint.ViewState?) {
		if sanitizedName != nil {
			(.enabled, nil)
		} else {
			(.disabled, .iconError(L10n.LinkedConnectors.RenameConnector.errorEmpty))
		}
	}
}

extension UpdateP2PLinkName {
	public struct ViewState: Equatable {
		let linkName: String
		let sanitizedName: NonEmptyString?
		let updateButtonControlState: ControlState
		let hint: Hint.ViewState?
		let textFieldFocused: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<UpdateP2PLinkName>
		@Environment(\.dismiss) var dismiss
		@FocusState private var textFieldFocus: Bool

		init(store: StoreOf<UpdateP2PLinkName>) {
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
						Text(L10n.LinkedConnectors.RenameConnector.title)
							.textStyle(.sheetTitle)
							.multilineTextAlignment(.center)

						Text(L10n.LinkedConnectors.RenameConnector.subtitle)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)

						let nameBinding = viewStore.binding(
							get: \.linkName,
							send: { .linkNameChanged($0) }
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
						Button(L10n.LinkedConnectors.RenameConnector.update, action: action)
							.buttonStyle(.primaryRectangular)
							.controlState(viewStore.updateButtonControlState)
					}
				}
			}
		}
	}
}
