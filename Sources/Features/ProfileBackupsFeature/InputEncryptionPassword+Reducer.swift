import Cryptography
import FeaturePrelude

public typealias EncryptionPassword = String

// MARK: - InputEncryptionPassword
public struct InputEncryptionPassword: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Mode: Sendable, Hashable {
			case decrypt(EncryptedProfileSnapshot)
			case loadThenEncrypt(withScheme: EncryptionScheme = .default)
			case encryptSpecific(ProfileSnapshot, withScheme: EncryptionScheme = .default)
		}

		public enum Field: String, Sendable, Hashable {
			case encryptionPassword
			case confirmPassword
		}

		var needToConfirm: Bool {
			switch mode {
			case .decrypt: return false
			case .encryptSpecific, .loadThenEncrypt: return true
			}
		}

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
		case loadProfileSnapshotToEncryptResult(TaskResult<ProfileSnapshot>, encryptionScheme: EncryptionScheme)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case successfullyDecrypted(encrypted: EncryptedProfileSnapshot, decrypted: ProfileSnapshot)
		case successfullyEncrypted(plaintext: ProfileSnapshot, encrypted: EncryptedProfileSnapshot)
	}

	@Dependency(\.jsonEncoder) var jsonEncoder
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.backupsClient) var backupsClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { [mode = state.mode] send in
				await send(.internal(.focusTextField(.encryptionPassword)))
				switch mode {
				case let .loadThenEncrypt(encryptionScheme):
					let result = await TaskResult { try await backupsClient.snapshotOfProfileForExport() }
					await send(.internal(.loadProfileSnapshotToEncryptResult(result, encryptionScheme: encryptionScheme)))
				case .encryptSpecific:
					break
				case .decrypt:
					break
				}
			}

		case .confirmedEncryptionPassword:
			precondition(!state.inputtedEncryptionPassword.isEmpty)
			precondition(state.inputtedEncryptionPassword == state.confirmedEncryptionPassword)

			let password = state.confirmedEncryptionPassword

			// FIXME: Version KDF!!
			let encryptionKey = EncryptionScheme.kdf(password: password)

			switch state.mode {
			case .loadThenEncrypt:
				preconditionFailure("should have loaded already...")
				loggerGlobal.error("Should have loaded the profile to encrypt already")
				return .send(.delegate(.dismiss))

			case let .encryptSpecific(snapshot, withScheme: encryptionScheme):
				do {
					let json = try jsonEncoder().encode(snapshot)
					let encryptedPayload = try encryptionScheme.encrypt(data: json, encryptionKey: encryptionKey)
					let encrypted = EncryptedProfileSnapshot(encryptedSnapshot: .init(data: encryptedPayload), encryptionScheme: encryptionScheme)
					return .send(.delegate(.successfullyEncrypted(plaintext: snapshot, encrypted: encrypted)))
				} catch {
					loggerGlobal.error("Failed to encrypt profile snapshot, error: \(error)")
					errorQueue.schedule(error)
					return .none
				}
			case let .decrypt(encrypted):
				do {
					let decrypted = try encrypted.decrypt(key: encryptionKey)
					return .send(.delegate(.successfullyDecrypted(encrypted: encrypted, decrypted: decrypted)))
				} catch {
					loggerGlobal.error("Failed to encrypt profile snapshot, error: \(error)")
					errorQueue.schedule(error)
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

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .focusTextField(focus):
			state.focusedField = focus
			return .none

		case let .loadProfileSnapshotToEncryptResult(.success(snapshotToEncrypt), encryptionScheme):
			state.mode = .encryptSpecific(snapshotToEncrypt, withScheme: encryptionScheme)
			return .none

		case let .loadProfileSnapshotToEncryptResult(.failure(error), _):
			let errorMsg = "Failed to load profile snapshot to encrypt, error: \(error)"
			loggerGlobal.error(.init(stringLiteral: errorMsg))
			errorQueue.schedule(error)
			return .none
		}
	}
}
