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

		var navigationTitle: LocalizedStringKey {
			// FIXME: Strings
			isEncrypting ? "Export backup" : "Import backup"
		}

		var continueButtonTitle: LocalizedStringKey {
			// FIXME: Strings
			isEncrypting ? "Encrypt backup" : "Decrypt backup"
		}

		var title: LocalizedStringKey {
			// FIXME: String
			isEncrypting ? "Encrypt backup before export" : "Decrypt backup to import"
		}

		var subtitle: LocalizedStringKey {
			// FIXME: String
			isEncrypting ? "If you forget this password you will not be able to decrypt the wallet backup file. Use a secure, unique password. Back it up somewhere." : "Enter the password you chose when you originally encrypted this wallet backup file."
		}

		var imageName: String {
			// FIXME: String
			isEncrypting ? "square.and.arrow.up" : "square.and.arrow.down"
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
						Image(systemName: viewStore.imageName)
							.resizable()
							.frame(.medium)
							.foregroundColor(.app.gray2)

						// FIXME: Strings
						Text(viewStore.title)
							.foregroundColor(.app.gray2)
							.textStyle(.body1Header)
							.multilineTextAlignment(.leading)

						Text(viewStore.subtitle)
							.foregroundColor(.app.gray3)
							.textStyle(.body1HighImportance)
							.multilineTextAlignment(.leading)

						AppTextField(
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
							AppTextField(
								// FIXME: Strings
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
				// FIXME: Strings
				.navigationTitle(viewStore.navigationTitle)
			}
		}
	}
}
