import SwiftUI

// MARK: - UpdateP2PLinkName.View
extension UpdateP2PLinkName {
	@MainActor
	public struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<UpdateP2PLinkName>
		@FocusState private var textFieldFocus: Bool

		init(store: StoreOf<UpdateP2PLinkName>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
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
							text: $store.linkName.sending(\.view.linkNameChanged),
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
						store.sanitizedName,
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

private extension UpdateP2PLinkName.State {
	var hint: Hint.ViewState? {
		sanitizedName == nil ? .iconError(L10n.LinkedConnectors.RenameConnector.errorEmpty) : nil
	}

	var controlState: ControlState {
		sanitizedName == nil ? .disabled : .enabled
	}
}
