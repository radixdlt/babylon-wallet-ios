import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - ImportMnemonic
public struct ImportMnemonic: Sendable, FeatureReducer {
	public static let wordsPerRow = 3

	public struct State: Sendable, Hashable {
		public typealias Words = IdentifiedArrayOf<ImportMnemonicWord.State>
		public var words: Words

		public var idOfWordWithTextFieldFocus: ImportMnemonicWord.State.ID?

		public var language: BIP39Language
		public var wordCount: BIP39WordCount {
			guard let wordCount = BIP39WordCount(wordCount: words.count) else {
				assertionFailure("Should never happen")
				return .twentyFour
			}
			return wordCount
		}

		public mutating func changeWordCount(to newWordCount: BIP39WordCount) {
			let wordCount = words.count
			let delta = Int(newWordCount.rawValue) - wordCount
			if delta > 0 {
				// is increasing word count
				words.append(contentsOf: (wordCount ..< Int(newWordCount.rawValue)).map {
					.init(
						id: $0,
						placeholder: ImportMnemonic.placeholder(
							index: $0,
							wordCount: newWordCount,
							language: language
						),
						isReadonlyMode: mode.readonly != nil
					)
				})
			} else if delta < 0 {
				// is decreasing word count
				words.removeLast(-delta)
			}
		}

		public var bip39Passphrase: String = ""

		public var mnemonic: Mnemonic? {
			guard completedWords.count == words.count else {
				return nil
			}
			return try? Mnemonic(
				words: completedWords
			)
		}

		public var completedWords: [BIP39Word] {
			words.compactMap(\.completeWord)
		}

		public let isWordCountFixed: Bool
		public var isAdvancedMode: Bool = false

		public let header: Header?
		public let warning: String?
		public let warningOnContinue: OnContinueWarning?

		public struct ReadonlyMode: Sendable, Hashable {
			public enum Context: Sendable, Hashable {
				case fromSettings
				case fromBackupPrompt
			}

			public let context: Context

			// FIXME: This aint pretty... but we are short on time, forgive me... we are putting WAY
			// to much logic and responsibility into this reducer here... for when a mnemonic is displayed
			// either from settings or from AccountDetails after user have pressed "Back up this mnemonic"
			// prompt, we need to able to mark a mnemonic as "backed up by user", we do so by use of
			// `FactorSourceIDFromHash` - which require a FactorSourceKind....
			public let factorSourceID: FactorSourceIDFromHash

			public init(context: Context, factorSourceID: FactorSourceIDFromHash) {
				self.context = context
				self.factorSourceID = factorSourceID
			}
		}

		public struct WriteMode: Sendable, Hashable {
			public var isProgressing: Bool
			public let persistStrategy: PersistStrategy?
			public let hideAdvancedMode: Bool
			public let showCloseButton: Bool
		}

		public enum Mode: Sendable, Hashable {
			case readonly(ReadonlyMode)
			case write(WriteMode)
			var readonly: ReadonlyMode? {
				switch self {
				case let .readonly(value): value
				case .write: nil
				}
			}

			var write: WriteMode? {
				switch self {
				case .readonly: nil
				case let .write(value): value
				}
			}

			mutating func update(isProgressing: Bool) {
				guard var write = self.write else {
					assertionFailure("Expected write mode")
					return
				}
				write.isProgressing = isProgressing
				self = .write(write)
			}
		}

		public var mode: Mode

		#if DEBUG
		public var debugMnemonicPhraseSingleField = ""
		#endif

		@PresentationState
		public var destination: Destination.State?

		public struct PersistStrategy: Sendable, Hashable {
			public enum Location: Sendable, Hashable {
				case intoKeychainAndProfile
			}

			public enum OnMnemonicExistsStrategy: Sendable, Hashable {
				case abort
				case appendWithCryptoParamaters
			}

			public let onMnemonicExistsStrategy: OnMnemonicExistsStrategy
			public let factorSourceKindOfMnemonic: OnDeviceMnemonicKind
			public let location: Location

			public init(
				factorSourceKindOfMnemonic: OnDeviceMnemonicKind,
				location: Location,
				onMnemonicExistsStrategy: OnMnemonicExistsStrategy
			) {
				self.factorSourceKindOfMnemonic = factorSourceKindOfMnemonic
				self.location = location
				self.onMnemonicExistsStrategy = onMnemonicExistsStrategy
			}
		}

		public struct OnContinueWarning: Sendable, Hashable {
			let title: String
			let text: String
			let button: String

			public init(title: String, text: String, button: String) {
				self.title = title
				self.text = text
				self.button = button
			}
		}

		public init(
			header: Header? = nil,
			warning: String? = nil,
			hideAdvancedMode: Bool = false,
			showCloseButton: Bool = false,
			warningOnContinue: OnContinueWarning? = nil,
			isWordCountFixed: Bool = false,
			persistStrategy: PersistStrategy?,
			language: BIP39Language = .english,
			wordCount: BIP39WordCount = .twelve,
			bip39Passphrase: String = ""
		) {
			precondition(wordCount.rawValue.isMultiple(of: UInt8(ImportMnemonic.wordsPerRow)))

			self.mode = .write(
				.init(
					isProgressing: false,
					persistStrategy: persistStrategy,
					hideAdvancedMode: hideAdvancedMode,
					showCloseButton: showCloseButton
				)
			)
			self.language = language
			self.bip39Passphrase = bip39Passphrase

			self.isWordCountFixed = isWordCountFixed
			self.words = []
			self.header = header
			self.warning = warning
			self.warningOnContinue = warningOnContinue
			changeWordCount(to: wordCount)
		}

		public init(
			header: Header? = nil,
			warning: String? = nil,
			mnemonicWithPassphrase: MnemonicWithPassphrase,
			readonlyMode: ReadonlyMode
		) {
			self.header = header
			self.warning = warning
			self.warningOnContinue = nil

			let mnemonic = mnemonicWithPassphrase.mnemonic
			self.language = mnemonic.language
			self.mode = .readonly(readonlyMode)
			self.isWordCountFixed = true
			self.words = Self.words(from: mnemonic, isReadonlyMode: true)
			self.bip39Passphrase = mnemonicWithPassphrase.passphrase
		}

		public static func words(
			from mnemonic: Mnemonic,
			isReadonlyMode: Bool
		) -> Words {
			.init(
				uniqueElements: mnemonic.words
					.enumerated()
					.map {
						ImportMnemonicWord.State(
							id: $0.offset,
							value: .complete(
								text: $0.element.word,
								word: $0.element,
								completion: .auto(match: .exact)
							),
							placeholder: ImportMnemonic.placeholder(
								index: $0.offset,
								wordCount: mnemonic.wordCount,
								language: mnemonic.language
							),
							isReadonlyMode: isReadonlyMode
						)
					}
			)
		}

		public struct Header: Sendable, Hashable {
			public let title: String
			public let subtitle: String?

			public init(title: String, subtitle: String? = nil) {
				self.title = title
				self.subtitle = subtitle
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared

		case toggleModeButtonTapped
		case passphraseChanged(String)
		case changedWordCountTo(BIP39WordCount)
		case doneViewing
		case closeButtonTapped
		case backButtonTapped
		case continueButtonTapped(Mnemonic)

		#if DEBUG
		case debugCopyMnemonic
		case debugMnemonicChanged(String, continue: Bool = false)
		case debugUseBabylonTestingMnemonicWithActiveAccounts(continue: Bool)
		case debugUseOlympiaTestingMnemonicWithActiveAccounts(continue: Bool)
		case debugUseTestingMnemonicZooVote(continue: Bool)
		case debugPasteMnemonic
		#endif
	}

	public enum InternalAction: Sendable, Equatable {
		public struct IntermediaryResult: Sendable, Equatable {
			public let factorSource: FactorSource
			public let savedIntoProfile: Bool
		}

		case focusNext(ImportMnemonicWord.State.ID)
		case saveFactorSourceResult(
			TaskResult<IntermediaryResult>
		)
	}

	public enum ChildAction: Sendable, Equatable {
		case word(id: ImportMnemonicWord.State.ID, child: ImportMnemonicWord.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case persistedNewFactorSourceInProfile(FactorSource)
		case persistedMnemonicInKeychainOnly(FactorSource)
		case notPersisted(MnemonicWithPassphrase)
		case doneViewing(idOfBackedUpFactorSource: FactorSourceIdFromHash?) // `nil` means it was already marked as backed up
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case backupConfirmation(AlertState<Action.BackupConfirmation>)
			case onContinueWarning(AlertState<Action.OnContinueWarning>)
			case verifyMnemonic(VerifyMnemonic.State)
		}

		public enum Action: Sendable, Equatable {
			case backupConfirmation(BackupConfirmation)
			case verifyMnemonic(VerifyMnemonic.Action)
			case onContinueWarning(OnContinueWarning)

			public enum BackupConfirmation: Sendable, Hashable {
				case userHasBackedUp
				case userHasNotBackedUp
			}

			public enum OnContinueWarning: Sendable, Hashable {
				case buttonTapped
			}
		}

		public var body: some Reducer<State, Action> {
			Scope(state: /State.verifyMnemonic, action: /Action.verifyMnemonic) {
				VerifyMnemonic()
			}
		}
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.mnemonicClient) var mnemonicClient
	@Dependency(\.continuousClock) var clock
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.userDefaults) var userDefaults
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	#if DEBUG
	@Dependency(\.pasteboardClient) var pasteboardClient
	#endif

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.words, action: /Action.child .. ChildAction.word) {
				ImportMnemonicWord()
			}
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .word(id, child: .delegate(.lookupWord(input))):
			let lookUpResult = lookup(input: input, state)
			return updateWord(id: id, input: input, &state, lookupResult: lookUpResult)

		case let .word(id, child: .delegate(.lostFocus(displayText))):
			let lookupResult = lookup(input: displayText, state)
			switch lookupResult {
			case let .known(.ambigous(candidates, input)):
				if let exactMatch = candidates.first(where: { $0.word == input.rawValue }) {
					state.words[id: id]?.value = .complete(
						text: displayText,
						word: exactMatch,
						completion: ImportMnemonicWord.State.WordValue.Completion.auto(
							match: .exact
						)
					)
				} else {
					state.words[id: id]?.value = .incomplete(
						text: displayText,
						hasFailedValidation: true
					)
				}
				return .none

			case .unknown(.notInList):
				state.words[id: id]?.value = .incomplete(
					text: displayText,
					hasFailedValidation: true
				)
				return .none

			case let .known(.unambiguous(word, match, input)):
				return completeWith(word: word, completion: .auto(match: match), id: id, input: input.rawValue, &state)

			case .unknown(.tooShort):
				return .none
			}

		case let .word(id, child: .delegate(.userSelectedCandidate(candidate, input))):
			return completeWith(
				word: candidate,
				completion: .user,
				id: id,
				input: input,
				&state
			)

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return focusNext(&state)

		case let .passphraseChanged(passphrase):
			state.bip39Passphrase = passphrase
			return .none

		case .toggleModeButtonTapped:
			state.isAdvancedMode.toggle()
			return .none

		case let .changedWordCountTo(newWordCount):
			state.changeWordCount(to: newWordCount)
			return .none

		case let .continueButtonTapped(mnemonic):
			if let warningOnContinue = state.warningOnContinue {
				state.destination = .onContinueWarning(warningOnContinue)
				return .none
			}

			return continueWithMnemonic(mnemonic: mnemonic, in: &state)

		case .doneViewing:
			assert(state.mode.readonly != nil)
			return markAsBackedUpIfNeeded(&state)

		case .backButtonTapped:
			assert(state.mode.readonly?.context == .fromSettings)
			return markAsBackedUpIfNeeded(&state)

		case .closeButtonTapped:
			if state.mode.readonly?.context == .fromBackupPrompt {
				return markAsBackedUpIfNeeded(&state)
			} else if state.mode.write?.showCloseButton == true {
				return .run { _ in await dismiss() }
			} else {
				assertionFailure("Invalid mode: No close button should be visible")
				return .none
			}

		#if DEBUG
		case .debugCopyMnemonic:
			if let mnemonic = state.mnemonic?.phrase {
				pasteboardClient.copyString(mnemonic)
			}
			return .none

		case let .debugMnemonicChanged(mnemonic, continueAutomatically):
			state.debugMnemonicPhraseSingleField = mnemonic
			if let mnemonic = try? Mnemonic(phrase: mnemonic, language: state.language) {
				state.words = State.words(from: mnemonic, isReadonlyMode: state.mode.readonly != nil)
				if continueAutomatically {
					state.mode.update(isProgressing: true)
					return .send(.view(.continueButtonTapped(mnemonic)))
				}
			}

			return .none

		case .debugPasteMnemonic:
			let toPaste = pasteboardClient.getString() ?? ""
			return .send(.view(.debugMnemonicChanged(toPaste)))

		case let .debugUseOlympiaTestingMnemonicWithActiveAccounts(continueAutomatically):
			return .send(.view(.debugMnemonicChanged("section canoe half crystal crew balcony duty scout half robot avocado gas all effort piece", continue: continueAutomatically)))

		case let .debugUseBabylonTestingMnemonicWithActiveAccounts(continueAutomatically):
			return .send(.view(.debugMnemonicChanged("wine over village stage barrel strategy cushion decline echo fiber salad carry empower fun awful cereal galaxy laundry practice appear bean flat mansion license", continue: continueAutomatically)))

		case let .debugUseTestingMnemonicZooVote(continueAutomatically):
			return .send(.view(.debugMnemonicChanged(Mnemonic.sample24ZooVote.phrase, continue: continueAutomatically)))
		#endif
		}
	}

	private func continueWithMnemonic(mnemonic: Mnemonic, in state: inout State) -> Effect<Action> {
		guard let write = state.mode.write else {
			preconditionFailure("expected write mode")
		}
		state.mode.update(isProgressing: true)
		let mnemonicWithPassphrase = MnemonicWithPassphrase(
			mnemonic: mnemonic,
			passphrase: state.bip39Passphrase
		)
		guard let persistStrategy = write.persistStrategy else {
			state.mode.update(isProgressing: false)
			return .send(.delegate(.notPersisted(mnemonicWithPassphrase)))
		}
		switch persistStrategy.location {
		case .intoKeychainAndProfile:
			return .run { send in
				await send(.internal(.saveFactorSourceResult(
					TaskResult {
						let saveIntoProfile = true
						let factorSource = try await factorSourcesClient.addOnDeviceFactorSource(
							onDeviceMnemonicKind: persistStrategy.factorSourceKindOfMnemonic,
							mnemonicWithPassphrase: mnemonicWithPassphrase,
							onMnemonicExistsStrategy: persistStrategy.onMnemonicExistsStrategy,
							saveIntoProfile: saveIntoProfile
						)
						return .init(factorSource: factorSource.asGeneral, savedIntoProfile: saveIntoProfile)
					}
				)))
			}
		}
	}

	private func markAsBackedUpIfNeeded(_ state: inout State) -> Effect<Action> {
		guard let factorSourceID = state.mode.readonly?.factorSourceID else {
			return .none
		}

		let listOfBackedUpMnemonics = userDefaults.getFactorSourceIDOfBackedUpMnemonics()
		if listOfBackedUpMnemonics.contains(factorSourceID) {
			return .send(.delegate(.doneViewing(idOfBackedUpFactorSource: nil))) // user has already marked this mnemonic as "backed up"
		} else {
			state.destination = .askUserIfSheHasBackedUpMnemonic()
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .focusNext(id):
			state.idOfWordWithTextFieldFocus = id
			state.words[id: id]?.focus()
			return .none

		case let .saveFactorSourceResult(.failure(error)):
			state.mode.update(isProgressing: false)
			errorQueue.schedule(error)
			loggerGlobal.error("Failed to save mnemonic in profile, error: \(error)")
			return .none

		case let .saveFactorSourceResult(.success(saved)):
			state.mode.update(isProgressing: false)
			overlayWindowClient.scheduleHUD(.seedPhraseImported)
			let factorSource = saved.factorSource

			if saved.savedIntoProfile {
				return .send(.delegate(.persistedNewFactorSourceInProfile(factorSource)))
			} else {
				return .send(.delegate(.persistedMnemonicInKeychainOnly(factorSource)))
			}
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .backupConfirmation(.userHasBackedUp):
			guard let mnemonic = state.mnemonic else {
				return .none
			}
			state.destination = .verifyMnemonic(.init(mnemonic: mnemonic))
			return .none

		case .backupConfirmation(.userHasNotBackedUp):
			loggerGlobal.notice("User have not backed up")
			return .send(.delegate(.doneViewing(idOfBackedUpFactorSource: nil)))

		case .onContinueWarning(.buttonTapped):
			guard let mnemonic = state.mnemonic else {
				loggerGlobal.error("Can't read mnemonic")
				struct FailedToReadMnemonic: Error {}
				errorQueue.schedule(FailedToReadMnemonic())
				return .none
			}
			return continueWithMnemonic(mnemonic: mnemonic, in: &state)

		case .verifyMnemonic(.delegate(.mnemonicVerified)):
			guard let factorSourceID = state.mode.readonly?.factorSourceID else {
				return .none
			}
			return .run { send in
				try userDefaults.addFactorSourceIDOfBackedUpMnemonic(factorSourceID)
				await send(.delegate(.doneViewing(idOfBackedUpFactorSource: factorSourceID)))
			} catch: { error, _ in
				loggerGlobal.error("Failed to save mnemonic as backed up")
				errorQueue.schedule(error)
			}

		default:
			return .none
		}
	}
}

extension ImportMnemonic {
	private func lookup(input: String, _ state: State) -> BIP39LookupResult {
		mnemonicClient.lookup(.init(
			language: state.language,
			input: input,
			minLenghForCandidatesLookup: 2
		))
	}

	private func completeWith(
		word: BIP39Word,
		completion: ImportMnemonicWord.State.WordValue.Completion,
		id: ImportMnemonicWord.State.ID,
		input: String,
		_ state: inout State
	) -> Effect<Action> {
		state.words[id: id]?.value = .complete(text: input, word: word, completion: completion)
		return focusNext(&state)
	}

	private func updateWord(
		id: ImportMnemonicWord.State.ID,
		input: String,
		_ state: inout State,
		lookupResult: BIP39LookupResult
	) -> Effect<Action> {
		// FIXME: - 1.5.4 hot fix
		/// Words strip is broken in latest iOS versions, so we don't count on users selecting the word
		/// dissambiguate between them. Rather the Wallet will validate the word eagerly if it is a valid one.
		/// Behaviour:
		/// - User enters the first two characters, having the word `en` - the word is incomplete.
		/// - User enters another character, having the word`end` - the word is valid.
		/// - User enters additional character, having the word `endl` - the word is incomplete.
		/// - User enters additional characters, having the word `endless` - the word is considered valid.
		/// - User removes some characters, having the word `endle` - the word is incomplete.
		/// - User removes more characters, having the word `end` - the word is valid.
		/// - User removes another character, having the word `en` - the word is incomplete.
		switch lookupResult {
		case let .known(.ambigous(candidates, nonEmptyInput)):
			guard let userInput = candidates.first(where: { $0.word == nonEmptyInput }) else {
				state.words[id: id]?.value = .incomplete(text: input, hasFailedValidation: false)
				return .none
			}

			return completeWith(word: userInput, completion: .user, id: id, input: input, &state)

		case let .known(.unambiguous(word, _, _)):
			guard word.word.rawValue == input else {
				state.words[id: id]?.value = .incomplete(text: input, hasFailedValidation: false)
				return .none
			}
			return completeWith(word: word, completion: .user, id: id, input: input, &state)

		case .unknown(.notInList):
			state.words[id: id]?.value = .incomplete(text: input, hasFailedValidation: true)
			return .none

		case .unknown(.tooShort):
			state.words[id: id]?.value = .incomplete(text: input, hasFailedValidation: false)
			return .none
		}
	}

	private func focusNext(_ state: inout State) -> Effect<Action> {
		if let current = state.idOfWordWithTextFieldFocus {
			state.words[id: current]?.resignFocus()
		}
		guard let nextID = state.words.first(where: { !$0.isComplete })?.id else {
			return .none
		}

		return .run { send in
			try? await clock.sleep(for: .milliseconds(75))
			await send(.internal(.focusNext(nextID)))
		}
	}
}

extension ImportMnemonic {
	static func placeholder(
		index: Int,
		wordCount: BIP39WordCount,
		language: BIP39Language
	) -> String {
		precondition(index <= 23, "Invalid BIP39 word index, got index: \(index), exected less than 24.")
		let word: BIP39Word = {
			let wordList = language.wordlist() // BIP39.wordList(for: language)
			switch language {
			case .english:
				let bip39Alphabet = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", /* X is missing */ "y", "z"]
				return wordList
					// we use `last` simply because we did not like the words "abandon baby"
					// which we get by using `first`, too sad a combination.
					.last(
						where: { $0.word.hasPrefix(bip39Alphabet[index]) }
					)!

			default:
				let scale = UInt16(89) // 2048 / 23
				let indexScaled = U11(inner: scale * UInt16(index))
				return wordList.first(where: { $0.index == indexScaled })!
			}

		}()
		return word.word
	}
}

extension ImportMnemonic.Destination.State {
	fileprivate static func askUserIfSheHasBackedUpMnemonic() -> Self {
		.backupConfirmation(.init(
			title: { TextState(L10n.ImportMnemonic.BackedUpAlert.title) },
			actions: {
				ButtonState(action: .userHasBackedUp, label: { TextState(L10n.ImportMnemonic.BackedUpAlert.confirmAction) })
				ButtonState(action: .userHasNotBackedUp, label: { TextState(L10n.ImportMnemonic.BackedUpAlert.noAction) })
			},
			message: { TextState(L10n.ImportMnemonic.BackedUpAlert.message) }
		))
	}

	fileprivate static func onContinueWarning(
		_ warning: ImportMnemonic.State.OnContinueWarning
	) -> Self {
		.onContinueWarning(.init(
			title: { TextState(warning.title) },
			actions: {
				ButtonState(action: .buttonTapped, label: { TextState(warning.button) })
			},
			message: { TextState(warning.text) }
		))
	}
}
