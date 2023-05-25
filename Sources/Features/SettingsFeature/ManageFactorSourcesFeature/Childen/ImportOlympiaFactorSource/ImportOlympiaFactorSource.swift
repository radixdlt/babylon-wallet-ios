import Cryptography
import FeaturePrelude
import ImportMnemonicFeature
import MnemonicClient

// MARK: - ImportOlympiaFactorSource
public struct ImportOlympiaFactorSource: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let shouldPersist: Bool

		public var canTapAlreadyImportedButton: Bool
		public var selectedAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>?

		public var importMnemonic: ImportMnemonic.State
		@PresentationState var foundNoExistFactorSourceAlert: AlertState<ViewAction.FoundNoFactorSourceAction>?

		public init(
			shouldPersist: Bool = true,
			canTapAlreadyImportedButton: Bool = true,
			language: BIP39.Language = .english,
			wordCount: BIP39.WordCount = .twelve,
			selectedAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>? = nil
		) {
			self.shouldPersist = shouldPersist
			self.canTapAlreadyImportedButton = canTapAlreadyImportedButton
			self.selectedAccounts = selectedAccounts
			self.importMnemonic = .init(language: language, wordCount: wordCount)
//			#if DEBUG
//			if let new = try? Mnemonic(phrase: "gentle hawk winner rain embrace erosion call update photo frost fatal wrestle", language: .english) {
//				self.mnemonic = new.phrase.rawValue
//				self.expectedWordCount = new.wordCount
//			}
//			#endif
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case closeButtonTapped
		case alreadyImportedButtonTapped
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
		case checkedIfOlympiaFactorSourceAlreadyExists(FactorSourceID?)
		case importOlympiaFactorSourceResult(TaskResult<FactorSourceID>)
	}

	public enum ChildAction: Sendable, Equatable {
		case importMnemonic(ImportMnemonic.Action)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.mnemonicClient) var mnemonicClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.importMnemonic, action: /Action.child .. ChildAction.importMnemonic) {
			ImportMnemonic()
		}
		Reduce(core)
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .importMnemonic(.delegate(.finishedInputtingMnemonicWithPassphrase(mnemonicWithPassphrase))):
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

		default: return .none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .foundNoExistFactorSourceAlert(.dismiss):
			return .none
		case .foundNoExistFactorSourceAlert(.presented(.okButtonTapped)):
			state.foundNoExistFactorSourceAlert = nil
			state.canTapAlreadyImportedButton = false
			return .none

		case .appeared:
			return .none

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

		case let .importOlympiaFactorSourceResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .importOlympiaFactorSourceResult(.success(factorSourceID)):
			return .send(.delegate(.persisted(factorSourceID)))
		}
	}
}
