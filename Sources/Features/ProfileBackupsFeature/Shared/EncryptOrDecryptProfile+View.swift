import FeaturePrelude

extension EncryptOrDecryptProfile.State {
	var viewState: EncryptOrDecryptProfile.ViewState {
		.init(
			inputtedEncryptionPassword: inputtedEncryptionPassword,
			confirmedEncryptionPassword: confirmedEncryptionPassword,
			focusedField: focusedField,
			isEncrypting: isEncrypting
		)
	}
}

// MARK: - EncryptOrDecryptProfile.View
extension EncryptOrDecryptProfile {
	public struct ViewState: Equatable {
		let inputtedEncryptionPassword: String
		let confirmedEncryptionPassword: String
		let focusedField: State.Field?
		let isEncrypting: Bool

		var controlState: ControlState {
			if isEncrypting {
				return isConfirmingPasswordValid ? .enabled : .disabled
			} else {
				return isNonConfirmingPasswordValid ? .enabled : .disabled
			}
		}

		var isNonConfirmingPasswordValid: Bool {
			!inputtedEncryptionPassword.isEmpty
		}

		var isConfirmingPasswordValid: Bool {
			guard isNonConfirmingPasswordValid else {
				return false
			}
			return confirmedEncryptionPassword == inputtedEncryptionPassword
		}

		var confirmHint: Hint? {
			guard needToConfirm else { return nil }
			if inputtedEncryptionPassword.isEmpty || !confirmedEncryptionPassword.isEmpty && focusedField != .confirmPassword {
				return nil
			}
			if !confirmedEncryptionPassword.isEmpty, confirmedEncryptionPassword != inputtedEncryptionPassword {
				return .error("Passwords do not match")
			}

			return nil
		}

		var needToConfirm: Bool {
			isEncrypting
		}

		var continueButtonTitle: String {
			// FIXME: Strings
			"Continue"
		}

		var title: String {
			// FIXME: String
			let operation = isEncrypting ? "Encrypt" : "Decrypt"
			return "\(operation) Wallet Backup File"
		}

		var subtitle: String {
			// FIXME: String
			isEncrypting ? "Enter a password to encrypt this wallet backup file. You will be required to enter this password when recovering your Wallet from this file." : "Enter the password you chose when you originally encrypted this Wallet Backup file."
		}

		var nonConfirmingPasswordPlaceholder: String {
			// FIXME: String
			isEncrypting ? "Encryption password" : "Decryption password"
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<EncryptOrDecryptProfile>
		@FocusState private var focusedField: State.Field?

		public init(store: StoreOf<EncryptOrDecryptProfile>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack(spacing: .medium2) {
						Text(viewStore.title)
							.lineLimit(2)
							.textStyle(.sheetTitle)
							.foregroundColor(.app.gray1)

						Text(viewStore.subtitle)
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)

						AppTextField(
							useSecureField: true,
							placeholder: viewStore.nonConfirmingPasswordPlaceholder,
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
						#endif // iOS
						.autocorrectionDisabled()

						if viewStore.needToConfirm {
							// FIXME: Strings
							AppTextField(
								useSecureField: true,
								placeholder: "Confirm password",
								text: viewStore.binding(
									get: \.confirmedEncryptionPassword,
									send: { .passwordConfirmationChanged($0) }
								),
								hint: viewStore.confirmHint,
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
							#endif // iOS
							.autocorrectionDisabled()
						}
					}
					.padding([.bottom, .horizontal], .medium1)
				}
				.footer {
					Button(viewStore.continueButtonTitle) {
						viewStore.send(.confirmedEncryptionPassword)
					}
					.buttonStyle(.primaryRectangular)
					.controlState(viewStore.controlState)
				}
				.alert(
					store: store.destination,
					state: /EncryptOrDecryptProfile.Destination.State.incorrectPasswordAlert,
					action: EncryptOrDecryptProfile.Destination.Action.incorrectPasswordAlert
				)
				.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

extension StoreOf<EncryptOrDecryptProfile> {
	fileprivate var destination: PresentationStoreOf<EncryptOrDecryptProfile.Destination> {
		scope(state: \.$destination, action: { .child(.destination($0)) })
	}
}
