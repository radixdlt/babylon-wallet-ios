import ComposableArchitecture
import SwiftUI

extension EncryptOrDecryptProfile.State {
	var viewState: EncryptOrDecryptProfile.ViewState {
		.init(
			enteredEncryptionPassword: enteredEncryptionPassword,
			confirmedEncryptionPassword: confirmedEncryptionPassword,
			focusedField: focusedField,
			isEncrypting: isEncrypting
		)
	}
}

// MARK: - EncryptOrDecryptProfile.View
extension EncryptOrDecryptProfile {
	struct ViewState: Equatable {
		let enteredEncryptionPassword: String
		let confirmedEncryptionPassword: String
		let focusedField: State.Field?
		let isEncrypting: Bool

		var controlState: ControlState {
			if isEncrypting {
				isConfirmingPasswordValid ? .enabled : .disabled
			} else {
				isNonConfirmingPasswordValid ? .enabled : .disabled
			}
		}

		var isNonConfirmingPasswordValid: Bool {
			!enteredEncryptionPassword.isEmpty
		}

		var isConfirmingPasswordValid: Bool {
			guard isNonConfirmingPasswordValid else {
				return false
			}
			return confirmedEncryptionPassword == enteredEncryptionPassword
		}

		var confirmHint: Hint.ViewState? {
			guard needToConfirm else { return nil }
			if enteredEncryptionPassword.isEmpty || !confirmedEncryptionPassword.isEmpty && focusedField != .confirmPassword {
				return nil
			}
			if !confirmedEncryptionPassword.isEmpty, confirmedEncryptionPassword != enteredEncryptionPassword {
				return .iconError(L10n.ProfileBackup.ManualBackups.passwordsMissmatchError)
			}

			return nil
		}

		var needToConfirm: Bool {
			isEncrypting
		}

		var continueButtonTitle: String {
			L10n.Common.continue
		}

		var title: String {
			isEncrypting
				? L10n.ProfileBackup.ManualBackups.encryptBackupTitle
				: L10n.ProfileBackup.ManualBackups.decryptBackupTitle
		}

		var subtitle: String {
			isEncrypting
				? L10n.ProfileBackup.ManualBackups.encryptBackupSubtitle
				: L10n.ProfileBackup.ManualBackups.decryptBackupSubtitle
		}

		var nonConfirmingPasswordPlaceholder: String {
			isEncrypting
				? L10n.ProfileBackup.ManualBackups.nonConformingEncryptionPasswordPlaceholder
				: L10n.ProfileBackup.ManualBackups.nonConformingDecryptionPasswordPlaceholder
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<EncryptOrDecryptProfile>
		@FocusState private var focusedField: State.Field?

		init(store: StoreOf<EncryptOrDecryptProfile>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack(spacing: .medium2) {
						Text(viewStore.title)
							.multilineTextAlignment(.center)
							.lineLimit(2)
							.textStyle(.sheetTitle)
							.foregroundColor(.app.gray1)

						Text(viewStore.subtitle)
							.multilineTextAlignment(.center)
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)
							.padding(.horizontal, .large2)

						AppTextField(
							useSecureField: true,
							placeholder: viewStore.nonConfirmingPasswordPlaceholder,
							text: viewStore.binding(
								get: \.enteredEncryptionPassword,
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
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
						.padding(.horizontal, .medium1)

						if viewStore.needToConfirm {
							AppTextField(
								useSecureField: true,
								placeholder: L10n.ProfileBackup.ManualBackups.confirmPasswordPlaceholder,
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
							.textInputAutocapitalization(.never)
							.autocorrectionDisabled()
							.padding(.horizontal, .medium1)
						}
					}
					.padding(.bottom, .medium1)
				}
				.footer {
					Button(viewStore.continueButtonTitle) {
						viewStore.send(.confirmedEncryptionPassword)
					}
					.buttonStyle(.primaryRectangular)
					.controlState(viewStore.controlState)
				}
				.destinations(with: store)
				.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

private extension StoreOf<EncryptOrDecryptProfile> {
	var destination: PresentationStoreOf<EncryptOrDecryptProfile.Destination> {
		func scopeState(state: State) -> PresentationState<EncryptOrDecryptProfile.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<EncryptOrDecryptProfile>) -> some View {
		let destinationStore = store.destination
		return alert(
			store: destinationStore,
			state: /EncryptOrDecryptProfile.Destination.State.incorrectPasswordAlert,
			action: EncryptOrDecryptProfile.Destination.Action.incorrectPasswordAlert
		)
	}
}
