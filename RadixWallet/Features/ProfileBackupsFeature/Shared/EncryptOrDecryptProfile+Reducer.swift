import ComposableArchitecture
import SwiftUI
public typealias EncryptionPassword = String

// MARK: - EncryptOrDecryptProfile
public struct EncryptOrDecryptProfile: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Mode: Sendable, Hashable {
			case decrypt(EncryptedProfileSnapshot)

			case loadThenEncrypt(
				kdfScheme: PasswordBasedKeyDerivationScheme = .default,
				encryptionScheme: EncryptionScheme = .default
			)

			case encryptSpecific(
				profileSnapshot: ProfileSnapshot,
				kdfScheme: PasswordBasedKeyDerivationScheme = .default,
				encryptionScheme: EncryptionScheme = .default
			)

			var isDecrypt: Bool {
				switch self {
				case .decrypt: true
				case .loadThenEncrypt, .encryptSpecific: false
				}
			}
		}

		public enum Field: String, Sendable, Hashable {
			case encryptionPassword
			case confirmPassword
		}

		var isEncrypting: Bool {
			switch mode {
			case .decrypt: false
			case .encryptSpecific, .loadThenEncrypt: true
			}
		}

		@PresentationState
		public var destination: Destination_.State? = nil

		public var mode: Mode
		var focusedField: Field?
		var inputtedEncryptionPassword: String = ""
		var confirmedEncryptionPassword: String = ""

		public init(mode: Mode) {
			self.mode = mode
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case closeButtonTapped
		case textFieldFocused(State.Field?)
		case passwordChanged(String)
		case passwordConfirmationChanged(String)
		case confirmedEncryptionPassword
	}

	public enum InternalAction: Sendable, Equatable {
		case focusTextField(State.Field?)

		case loadProfileSnapshotToEncryptResult(
			TaskResult<ProfileSnapshot>,
			kdfScheme: PasswordBasedKeyDerivationScheme,
			encryptionScheme: EncryptionScheme
		)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case successfullyDecrypted(encrypted: EncryptedProfileSnapshot, decrypted: ProfileSnapshot)
		case successfullyEncrypted(plaintext: ProfileSnapshot, encrypted: EncryptedProfileSnapshot)
	}

	// MARK: - Destination

	public struct Destination_: DestinationReducer {
		public enum State: Hashable, Sendable {
			case incorrectPasswordAlert(AlertState<Action.IncorrectPasswordAlert>)
		}

		public enum Action: Equatable, Sendable {
			case incorrectPasswordAlert(IncorrectPasswordAlert)

			public enum IncorrectPasswordAlert: Sendable, Hashable {
				case okTapped
			}
		}

		public var body: some ReducerOf<Self> {
			EmptyReducer()
		}
	}

	@Dependency(\.jsonEncoder) var jsonEncoder
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.backupsClient) var backupsClient

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.destination) {
				Destination_()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .destination(.presented(.incorrectPasswordAlert(.okTapped))):
			state.destination = nil
			return .none
		default:
			return .none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .run { [mode = state.mode] send in
				await send(.internal(.focusTextField(.encryptionPassword)))
				switch mode {
				case let .loadThenEncrypt(kdfScheme, encryptionScheme):
					let result = await TaskResult { try await backupsClient.snapshotOfProfileForExport() }

					await send(.internal(.loadProfileSnapshotToEncryptResult(
						result,
						kdfScheme: kdfScheme,
						encryptionScheme: encryptionScheme
					)))

				case .encryptSpecific:
					break
				case .decrypt:
					break
				}
			}

		case .confirmedEncryptionPassword:
			precondition(!state.inputtedEncryptionPassword.isEmpty)

			if !state.mode.isDecrypt {
				precondition(state.inputtedEncryptionPassword == state.confirmedEncryptionPassword)
			}

			let password = state.inputtedEncryptionPassword

			switch state.mode {
			case .loadThenEncrypt:
				loggerGlobal.error("Should have loaded the profile to encrypt already")
				preconditionFailure("should have loaded already...")
				return .send(.delegate(.dismiss))

			case let .encryptSpecific(snapshot, kdfScheme, encryptionScheme):
				do {
					let encrypted = try snapshot.encrypt(
						password: password,
						kdfScheme: kdfScheme,
						encryptionScheme: encryptionScheme
					)

					return .send(.delegate(.successfullyEncrypted(plaintext: snapshot, encrypted: encrypted)))
				} catch {
					loggerGlobal.error("Failed to encrypt profile snapshot, error: \(error)")
					state.destination = .incorrectPasswordAlert(encrypt: true)
					return .none
				}
			case let .decrypt(encrypted):
				do {
					let decrypted = try encrypted.decrypt(password: password)
					return .send(.delegate(.successfullyDecrypted(encrypted: encrypted, decrypted: decrypted)))
				} catch {
					loggerGlobal.error("Failed to encrypt profile snapshot, error: \(error)")
					state.destination = .incorrectPasswordAlert(encrypt: false)
					return .none
				}
			}

		case .closeButtonTapped:
			return .send(.delegate(.dismiss))

		case let .textFieldFocused(focus):
			return .run { send in
				await send(.internal(.focusTextField(focus)))
			}

		case let .passwordChanged(inputtedEncryptionPassword):
			state.inputtedEncryptionPassword = inputtedEncryptionPassword
			return .none

		case let .passwordConfirmationChanged(confirmingPassword):
			state.confirmedEncryptionPassword = confirmingPassword
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .focusTextField(focus):
			state.focusedField = focus
			return .none

		case let .loadProfileSnapshotToEncryptResult(.success(snapshotToEncrypt), kdfScheme, encryptionScheme):
			state.mode = .encryptSpecific(
				profileSnapshot: snapshotToEncrypt,
				kdfScheme: kdfScheme,
				encryptionScheme: encryptionScheme
			)
			return .none

		case let .loadProfileSnapshotToEncryptResult(.failure(error), _, _):
			let errorMsg = "Failed to load profile snapshot to encrypt, error: \(error)"
			loggerGlobal.error(.init(stringLiteral: errorMsg))
			errorQueue.schedule(error)
			return .none
		}
	}
}

extension EncryptOrDecryptProfile.Destination.State {
	fileprivate static func incorrectPasswordAlert(encrypt: Bool) -> Self {
		.incorrectPasswordAlert(.init(
			title: { TextState(L10n.ProfileBackup.IncorrectPasswordAlert.title) },
			actions: {
				ButtonState(action: .okTapped, label: { TextState(L10n.ProfileBackup.IncorrectPasswordAlert.okAction) })
			},
			message: {
				TextState(
					encrypt
						? L10n.ProfileBackup.IncorrectPasswordAlert.messageEncryption
						: L10n.ProfileBackup.IncorrectPasswordAlert.messageDecryption
				)
			}
		))
	}
}
