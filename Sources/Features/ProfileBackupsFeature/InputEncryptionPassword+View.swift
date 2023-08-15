import FeaturePrelude

extension InputEncryptionPassword.State {
	var viewState: InputEncryptionPassword.ViewState {
		.init(
			inputtedEncryptionPassword: inputtedEncryptionPassword,
			confirmedEncryptionPassword: confirmedEncryptionPassword,
			focusedField: focusedField,
			needToConfirm: needToConfirm,
			controlState: !inputtedEncryptionPassword.isEmpty && inputtedEncryptionPassword == confirmedEncryptionPassword ? .enabled : .disabled
		)
	}
}

// MARK: - InputEncryptionPassword.View
extension InputEncryptionPassword {
	public struct ViewState: Equatable {
		let inputtedEncryptionPassword: String
		let confirmedEncryptionPassword: String
		let focusedField: State.Field?
		let needToConfirm: Bool
		let controlState: ControlState
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<InputEncryptionPassword>
		@FocusState private var focusedField: State.Field?

		public init(store: StoreOf<InputEncryptionPassword>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack(spacing: .medium2) {
						// FIXME: Strings
						Text("Encryption password")
							.foregroundColor(.app.gray1)
							.textStyle(.sheetTitle)
							.multilineTextAlignment(.center)

						// FIXME: Strings
						Text("Do not forget this")
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)

						AppTextField(
							// FIXME: Strings
							placeholder: "Encryption password",
							text: viewStore.binding(
								get: \.inputtedEncryptionPassword,
								send: { .passwordChanged($0) }
							),
							focus: .on(
								.encryptionPassword,
								binding: viewStore.binding(
									get: \.focusedField,
									send: { .textFieldFocused($0) }
								),
								to: $focusedField
							)
						)
						#if os(iOS)
						.textInputAutocapitalization(.never)
						.keyboardType(.URL)
						#endif // iOS
						.autocorrectionDisabled()

						if viewStore.needToConfirm {
							AppTextField(
								// FIXME: Strings
								placeholder: "Confirm password",
								text: viewStore.binding(
									get: \.confirmedEncryptionPassword,
									send: { .passwordConfirmationChanged($0) }
								),
								focus: .on(
									.confirmPassword,
									binding: viewStore.binding(
										get: \.focusedField,
										send: { .textFieldFocused($0) }
									),
									to: $focusedField
								)
							)
							#if os(iOS)
							.textInputAutocapitalization(.never)
							.keyboardType(.URL)
							#endif // iOS
							.autocorrectionDisabled()
						}
					}
					.padding([.bottom, .horizontal], .medium1)
				}
				.footer {
					// FIXME: Strings
					Button("Confirm") {
						viewStore.send(.confirmedEncryptionPassword)
					}
					.buttonStyle(.primaryRectangular)
					.controlState(viewStore.controlState)
				}
				.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}
