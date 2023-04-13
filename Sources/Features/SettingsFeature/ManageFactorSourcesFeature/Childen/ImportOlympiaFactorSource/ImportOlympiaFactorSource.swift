import Cryptography
import FeaturePrelude
import MnemonicClient

// MARK: - ImportOlympiaFactorSource
public struct ImportOlympiaFactorSource: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Field: String, Sendable, Hashable {
			case mnemonic, passphrase
		}

		public let shouldPersist: Bool
		public var mnemonic: String
		public var expectedWordCount: BIP39.WordCount
		public var passphrase: String
		public var canTapAlreadyImportedButton: Bool
		public var selectedAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>?
		@BindingState public var focusedField: Field?

		@PresentationState var foundNoExistFactorSourceAlert: AlertState<ViewAction.FoundNoFactorSourceAction>?

		public init(
			shouldPersist: Bool = true,
			canTapAlreadyImportedButton: Bool = true,
			expectedWordCount: BIP39.WordCount = .twelve,
			mnemonic: String = "",
			passphrase: String = "",
			selectedAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>? = nil
		) {
			self.shouldPersist = shouldPersist
			self.canTapAlreadyImportedButton = canTapAlreadyImportedButton
			self.mnemonic = mnemonic
			self.expectedWordCount = expectedWordCount
			self.passphrase = passphrase
			self.selectedAccounts = selectedAccounts
			#if DEBUG
			if let new = (try? Mnemonic(phrase: "private sight rather cloud lock pelican barrel whisper spy more artwork crucial abandon among grow guilt control wrist memory group churn hen program sauce", language: .english))?.phrase {
				self.mnemonic = new
				self.expectedWordCount = .twentyFour
			}
			#endif
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case closeButtonTapped
		case importButtonTapped
		case alreadyImportedButtonTapped
		case mnemonicChanged(String)
		case passphraseChanged(String)
		case textFieldFocused(ImportOlympiaFactorSource.State.Field?)
		case foundNoExistFactorSourceAlert(PresentationAction<FoundNoFactorSourceAction>)
		public enum FoundNoFactorSourceAction: Sendable, Hashable {
			case okButtonTapped
		}
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case alreadyExists(FactorSourceID)
		case persisted(FactorSourceID)
		case notPersisted(MnemonicWithPassphrase)
	}

	public enum InternalAction: Sendable, Equatable {
		case focusTextField(ImportOlympiaFactorSource.State.Field?)
		case mnemonicFromPhraseResult(TaskResult<Mnemonic>)
		case checkedIfOlympiaFactorSourceAlreadyExists(FactorSourceID?)
		case importOlympiaFactorSourceResult(TaskResult<FactorSourceID>)
	}

	@Dependency(\.continuousClock) var clock
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.mnemonicClient) var mnemonicClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .foundNoExistFactorSourceAlert(.dismiss):
			return .none
		case .foundNoExistFactorSourceAlert(.presented(.okButtonTapped)):
			state.foundNoExistFactorSourceAlert = nil
			state.canTapAlreadyImportedButton = false
			return .none

		case .appeared:
			return .run { send in
				try await clock.sleep(for: .seconds(0.5))
				#if DEBUG
				await send(.internal(.focusTextField(.passphrase)))
				#else
				await send(.internal(.focusTextField(.mnemonic)))
				#endif
			}
		case .importButtonTapped:
			return .run { [mnemonicPhrase = state.mnemonic] send in
				await send(.internal(.mnemonicFromPhraseResult(TaskResult {
					try mnemonicClient.import(mnemonicPhrase, BIP39.Language?.none)
				})))
			}

		case .alreadyImportedButtonTapped:
			guard let selectedAccounts = state.selectedAccounts else {
				return .none
			}
			return .run { send in
				let idOfExistingFactorSource = await factorSourcesClient.checkIfHasOlympiaFactorSourceForAccounts(selectedAccounts)
				await send(.internal(.checkedIfOlympiaFactorSourceAlreadyExists(idOfExistingFactorSource)))
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
		case let .checkedIfOlympiaFactorSourceAlreadyExists(idOfExistingFactorSource):
			if let idOfExistingFactorSource {
				return .send(.delegate(.alreadyExists(idOfExistingFactorSource)))
			}
			state.foundNoExistFactorSourceAlert = .init(
				title: { TextState("Not found") },
				actions: {
					ButtonState(
						role: .cancel,
						action: .okButtonTapped
					) {
						TextState("OK")
					}
				},
				message: { TextState("Unable to validate public keys against existing mnemonics.") }
			)
			return .none

		case let .focusTextField(field):
			state.focusedField = field
			return .none

		case let .mnemonicFromPhraseResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .mnemonicFromPhraseResult(.success(mnemonic)):

			let mnemonicWithPassphrase = MnemonicWithPassphrase(
				mnemonic: mnemonic,
				passphrase: state.passphrase
			)

			guard state.shouldPersist else {
				return .send(.delegate(.notPersisted(mnemonicWithPassphrase)))
			}

			return .run { send in
				await send(.internal(.importOlympiaFactorSourceResult(
					TaskResult {
						try await factorSourcesClient.importOlympiaFactorSource(
							mnemonicWithPassphrase: mnemonicWithPassphrase
						)
					}
				)))
			}

		case let .importOlympiaFactorSourceResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .importOlympiaFactorSourceResult(.success(factorSourceID)):
			return .send(.delegate(.persisted(factorSourceID)))
		}
	}
}
