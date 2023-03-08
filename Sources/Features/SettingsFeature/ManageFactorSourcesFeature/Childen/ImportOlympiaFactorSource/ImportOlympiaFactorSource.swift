import Cryptography
import FeaturePrelude
import MnemonicClient

// MARK: - ImportOlympiaFactorSource
public struct ImportOlympiaFactorSource: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Field: String, Sendable, Hashable {
			case mnemonic, passphrase
		}

		public var mnemonic: String
		public var passphrase: String

		@BindingState public var focusedField: Field?

		public init(
			mnemonic: String = "",
			passphrase: String = ""
		) {
			self.mnemonic = mnemonic
			self.passphrase = passphrase
			#if DEBUG
			self.mnemonic = "spirit bird issue club alcohol flock skull health lemon judge piece eyebrow"
			#endif
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case closeButtonTapped
		case importButtonTapped
		case mnemonicChanged(String)
		case passphraseChanged(String)
		case textFieldFocused(ImportOlympiaFactorSource.State.Field?)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case imported
	}

	public enum InternalAction: Sendable, Equatable {
		case focusTextField(ImportOlympiaFactorSource.State.Field?)
		case mnemonicFromPhraseResult(TaskResult<Mnemonic>)
		case importOlympiaFactorSourceResult(TaskResult<EquatableVoid>)
	}

	@Dependency(\.continuousClock) var clock
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.mnemonicClient) var mnemonicClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				try await clock.sleep(for: .seconds(0.5))
				await send(.internal(.focusTextField(.mnemonic)))
			}
		case .importButtonTapped:
			return .run { [mnemonicPhrase = state.mnemonic] send in
				await send(.internal(.mnemonicFromPhraseResult(TaskResult {
					try mnemonicClient.import(mnemonicPhrase, BIP39.Language?.none)
				})))
			}

		case .closeButtonTapped:
			return .send(.delegate(.dismiss))

		case let .mnemonicChanged(mnemonic):
			state.mnemonic = mnemonic
			return .none
		case let .passphraseChanged(passphrase):
			state.passphrase = passphrase
			return .none
		case let .textFieldFocused(field):
			return .run { send in
				try await clock.sleep(for: .seconds(0.5))
				await send(.internal(.focusTextField(field)))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .focusTextField(field):
			state.focusedField = field
			return .none
		case let .mnemonicFromPhraseResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		case let .mnemonicFromPhraseResult(.success(mnemonic)):
			return .run { [passphrase = state.passphrase] send in
				await send(.internal(.importOlympiaFactorSourceResult(
					TaskResult {
						try await factorSourcesClient.importOlympiaFactorSource(
							MnemonicWithPassphrase(mnemonic: mnemonic, passphrase: passphrase)
						)
					}
				)))
			}
		case let .importOlympiaFactorSourceResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		case .importOlympiaFactorSourceResult(.success):
			return .send(.delegate(.imported))
		}
	}
}
