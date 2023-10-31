import ComposableArchitecture
import SwiftUI

// MARK: - ImportMnemonic
public struct ImportMnemonic: Sendable, FeatureReducer {
	public static let wordsPerRow = 3

	public struct State: Sendable, Hashable {
		public typealias Words = IdentifiedArrayOf<ImportMnemonicWord.State>
		public var words: Words

		public var idOfWordWithTextFieldFocus: ImportMnemonicWord.State.ID?

		public var language: BIP39.Language
		public var wordCount: BIP39.WordCount {
			guard let wordCount = BIP39.WordCount(wordCount: words.count) else {
				assertionFailure("Should never happen")
				return .twentyFour
			}
			return wordCount
		}

		public mutating func changeWordCount(by delta: Int) {
			let positiveDelta = abs(delta)
			precondition(positiveDelta.isMultiple(of: ImportMnemonic.wordsPerRow))

			let wordCount = words.count
			let newWordCount = BIP39.WordCount(wordCount: wordCount + delta)! // might in fact be subtraction
			if delta > 0 {
				// is increasing word count
				words.append(contentsOf: (wordCount ..< newWordCount.rawValue).map {
					.init(
						id: $0,
						placeholder: ImportMnemonic.placeholder(
							index: $0,
							wordCount: newWordCount,
							language: language
						),
						isReadonlyMode: readonlyMode != nil
					)
				})
			} else if delta < 0 {
				// is decreasing word count
				words.removeLast(positiveDelta)
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

		public var completedWords: [BIP39.Word] {
			words.compactMap(\.completeWord)
		}

		/// irrelevant for readonly
		public var isProgressing = false

		public let persistStrategy: PersistStrategy?

		public let readonlyMode: ReadonlyMode?
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
			// `FactorSourceID.FromHash` - which require a FactorSourceKind....
			public let factorSourceKind: FactorSourceKind

			public init(context: Context, factorSourceKind: FactorSourceKind) {
				self.context = context
				self.factorSourceKind = factorSourceKind
			}
		}

		#if DEBUG
		public var debugMnemonicPhraseSingleField = ""
		#endif

		@PresentationState
		public var destination: Destinations.State?

		public struct PersistStrategy: Sendable, Hashable {
			public enum Location: Sendable, Hashable {
				case intoKeychainAndProfile
				case intoKeychainOnly
			}

			public let mnemonicForFactorSourceKind: MnemonicBasedFactorSourceKind
			public let location: Location
			public init(mnemonicForFactorSourceKind: MnemonicBasedFactorSourceKind, location: Location) {
				self.mnemonicForFactorSourceKind = mnemonicForFactorSourceKind
				self.location = location
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
			warningOnContinue: OnContinueWarning? = nil,
			isWordCountFixed: Bool = false,
			persistStrategy: PersistStrategy?,
			language: BIP39.Language = .english,
			wordCount: BIP39.WordCount = .twelve,
			bip39Passphrase: String = "",
			offDeviceMnemonicInfoPrompt: OffDeviceMnemonicInfo.State? = nil
		) {
			precondition(wordCount.rawValue.isMultiple(of: ImportMnemonic.wordsPerRow))

			self.persistStrategy = persistStrategy
			self.language = language
			self.bip39Passphrase = bip39Passphrase

			self.readonlyMode = nil
			self.isWordCountFixed = isWordCountFixed
			self.words = []
			if let offDeviceMnemonicInfoPrompt {
				self.destination = .offDeviceMnemonicInfoPrompt(offDeviceMnemonicInfoPrompt)
			}
			self.header = header
			self.warning = warning
			self.warningOnContinue = warningOnContinue
			changeWordCount(by: wordCount.rawValue)
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
			self.persistStrategy = nil
			self.language = mnemonic.language
			self.readonlyMode = readonlyMode
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
								text: $0.element.word.rawValue,
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
		case addRowButtonTapped
		case removeRowButtonTapped
		case doneViewing
		case closeButtonTapped
		case backButtonTapped
		case continueButtonTapped(Mnemonic)

		#if DEBUG
		case debugCopyMnemonic
		case debugMnemonicChanged(String)
		case debugPasteMnemonic
		#endif
	}

	public enum InternalAction: Sendable, Equatable {
		case focusNext(ImportMnemonicWord.State.ID)
		case saveFactorSourceResult(TaskResult<FactorSource>)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
		case word(id: ImportMnemonicWord.State.ID, child: ImportMnemonicWord.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case persistedNewFactorSourceInProfile(FactorSource)
		case persistedMnemonicInKeychainOnly(MnemonicWithPassphrase, FactorSourceID.FromHash)
		case notPersisted(MnemonicWithPassphrase)
		case doneViewing(markedMnemonicAsBackedUp: Bool? = nil) // `nil` means it was already marked as backed up
	}

	public struct Destinations: Sendable, Reducer {
		public enum State: Sendable, Hashable {
			case offDeviceMnemonicInfoPrompt(OffDeviceMnemonicInfo.State)
			case markMnemonicAsBackedUp(AlertState<Action.MarkMnemonicAsBackedUpOrNot>)
			case onContinueWarning(AlertState<Action.OnContinueWarning>)
		}

		public enum Action: Sendable, Equatable {
			case offDeviceMnemonicInfoPrompt(OffDeviceMnemonicInfo.Action)

			case markMnemonicAsBackedUp(MarkMnemonicAsBackedUpOrNot)

			case onContinueWarning(OnContinueWarning)

			public enum MarkMnemonicAsBackedUpOrNot: Sendable, Hashable {
				case userHaveBackedUp(FactorSourceID.FromHash)
				case userHaveNotBackedUp
			}

			public enum OnContinueWarning: Sendable, Hashable {
				case buttonTapped
			}
		}

		public var body: some Reducer<State, Action> {
			Scope(state: /State.markMnemonicAsBackedUp, action: /Action.markMnemonicAsBackedUp) {
				EmptyReducer()
			}
			Scope(state: /State.offDeviceMnemonicInfoPrompt, action: /Action.offDeviceMnemonicInfoPrompt) {
				OffDeviceMnemonicInfo()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.mnemonicClient) var mnemonicClient
	@Dependency(\.continuousClock) var clock
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.userDefaultsClient) var userDefaultsClient

	#if DEBUG
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.pasteboardClient) var pasteboardClient
	#endif

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.words, action: /Action.child .. ChildAction.word) {
				ImportMnemonicWord()
			}
			.ifLet(\.$destination, action: /Action.child .. /ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .word(id, child: .delegate(.lookupWord(input))):
			let lookUpResult = lookup(input: input, state)
			return updateWord(id: id, input: input, &state, lookupResult: lookUpResult)

		case let .word(id, child: .delegate(.lostFocus(displayText))):
			switch lookup(input: displayText, state) {
			case let .known(.ambigous(candidates, input)):
				if let exactMatch = candidates.first(where: { $0.word == input }) {
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

			case .known(.unambiguous), .unknown(.tooShort):
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

		case let .destination(.presented(.offDeviceMnemonicInfoPrompt(.delegate(.done(label, mnemonicWithPassphrase))))):
			state.destination = nil
			guard let persistStrategy = state.persistStrategy else {
				preconditionFailure("expected persistStrategy")
				return .none
			}
			precondition(persistStrategy.mnemonicForFactorSourceKind == .offDevice)

			return .run { send in
				await send(.internal(.saveFactorSourceResult(
					TaskResult {
						try await factorSourcesClient.addOffDeviceFactorSource(
							mnemonicWithPassphrase: mnemonicWithPassphrase,
							label: label
						)
					}
				)))
			}

		case let .destination(.presented(.markMnemonicAsBackedUp(.userHaveBackedUp(factorSourceID)))):
			return .run { send in
				try userDefaultsClient.addFactorSourceIDOfBackedUpMnemonic(factorSourceID)
				await send(.delegate(.doneViewing(markedMnemonicAsBackedUp: true)))
			} catch: { error, _ in
				loggerGlobal.error("Failed to save mnemonic as backed up")
				errorQueue.schedule(error)
			}

		case .destination(.presented(.markMnemonicAsBackedUp(.userHaveNotBackedUp))):
			loggerGlobal.notice("User have not backed up")
			return .send(.delegate(.doneViewing(markedMnemonicAsBackedUp: false)))

		case .destination(.presented(.onContinueWarning(.buttonTapped))):
			guard let mnemonic = state.mnemonic else {
				loggerGlobal.error("Can't read mnemonic")
				struct FailedToReadMnemonic: Error {}
				errorQueue.schedule(FailedToReadMnemonic())
				return .none
			}
			return continueWithMnemonic(mnemonic: mnemonic, in: &state)

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

		case .addRowButtonTapped:
			state.changeWordCount(by: +ImportMnemonic.wordsPerRow)
			return .none

		case .removeRowButtonTapped:
			state.changeWordCount(by: -ImportMnemonic.wordsPerRow)
			return .none

		case let .continueButtonTapped(mnemonic):
			if let warningOnContinue = state.warningOnContinue {
				state.destination = .onContinueWarning(warningOnContinue)
				return .none
			}

			return continueWithMnemonic(mnemonic: mnemonic, in: &state)

		case .doneViewing:
			assert(state.readonlyMode != nil)
			return markAsBackedUpIfNeeded(&state)

		case .backButtonTapped:
			assert(state.readonlyMode?.context == .fromSettings)
			return markAsBackedUpIfNeeded(&state)

		case .closeButtonTapped:
			assert(state.readonlyMode?.context == .fromBackupPrompt)
			return markAsBackedUpIfNeeded(&state)

		#if DEBUG
		case .debugCopyMnemonic:
			if let mnemonic = state.mnemonic?.phrase.rawValue {
				pasteboardClient.copyString(mnemonic)
			}
			return .none

		case let .debugMnemonicChanged(mnemonic):
			state.debugMnemonicPhraseSingleField = mnemonic
			if let mnemonic = try? Mnemonic(phrase: mnemonic, language: state.language) {
				state.words = State.words(from: mnemonic, isReadonlyMode: state.readonlyMode != nil)
				state.isProgressing = true
				return .send(.view(.continueButtonTapped(mnemonic)))
			} else {
				return .none
			}

		case .debugPasteMnemonic:
			let toPaste = pasteboardClient.getString() ?? ""
			return .send(.view(.debugMnemonicChanged(toPaste)))
		#endif
		}
	}

	private func continueWithMnemonic(mnemonic: Mnemonic, in state: inout State) -> Effect<Action> {
		state.isProgressing = true
		let mnemonicWithPassphrase = MnemonicWithPassphrase(
			mnemonic: mnemonic,
			passphrase: state.bip39Passphrase
		)
		guard let persistStrategy = state.persistStrategy else {
			return .send(.delegate(.notPersisted(mnemonicWithPassphrase)))
		}
		switch persistStrategy.location {
		case .intoKeychainAndProfile:
			switch persistStrategy.mnemonicForFactorSourceKind {
			case .offDevice:
				state.destination = .offDeviceMnemonicInfoPrompt(.init(
					mnemonicWithPassphrase: mnemonicWithPassphrase
				))
				return .none

			case let .onDevice(onDeviceKind):
				return .run { send in
					await send(.internal(.saveFactorSourceResult(
						TaskResult {
							try await factorSourcesClient.addOnDeviceFactorSource(
								onDeviceMnemonicKind: onDeviceKind,
								mnemonicWithPassphrase: mnemonicWithPassphrase
							)
						}
					)))
				}
			}
		case .intoKeychainOnly:
			return .run { send in
				await send(.internal(.saveFactorSourceResult(
					TaskResult {
						try await factorSourcesClient.addOnDeviceFactorSource(
							onDeviceMnemonicKind: .babylon,
							mnemonicWithPassphrase: mnemonicWithPassphrase,
							saveIntoProfile: false
						)
					}
				)))
			}
		}
	}

	private func markAsBackedUpIfNeeded(_ state: inout State) -> Effect<Action> {
		guard
			let readonlyMode = state.readonlyMode,
			let mnemonic = state.mnemonic,
			case let mnemonicWithPassphrase = MnemonicWithPassphrase(mnemonic: mnemonic, passphrase: state.bip39Passphrase),
			let factorSourceID = try? FactorSourceID.FromHash(
				kind: readonlyMode.factorSourceKind,
				mnemonicWithPassphrase: mnemonicWithPassphrase
			)
		else {
			return .none
		}

		let listOfBackedUpMnemonics = userDefaultsClient.getFactorSourceIDOfBackedUpMnemonics()
		if listOfBackedUpMnemonics.contains(factorSourceID) {
			return .send(.delegate(.doneViewing(markedMnemonicAsBackedUp: nil))) // user has already marked this mnemonic as "backed up"
		} else {
			state.destination = .askUserIfSheHasBackedUpMnemonic(factorSourceID)
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
			state.isProgressing = false
			errorQueue.schedule(error)
			loggerGlobal.error("Failed to save mnemonic in profile, error: \(error)")
			return .none

		case let .saveFactorSourceResult(.success(factorSource)):
			state.isProgressing = false
			return .send(.delegate(.persistedNewFactorSourceInProfile(factorSource)))
		}
	}
}

extension ImportMnemonic {
	private func lookup(input: String, _ state: State) -> BIP39.WordList.LookupResult {
		mnemonicClient.lookup(.init(
			language: state.language,
			input: input,
			minLenghForCandidatesLookup: 2
		))
	}

	private func completeWith(
		word: BIP39.Word,
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
		lookupResult: BIP39.WordList.LookupResult
	) -> Effect<Action> {
		switch lookupResult {
		case let .known(.ambigous(candidates, nonEmptyInput)):
			state.words[id: id]?.autocompletionCandidates = .init(input: nonEmptyInput, candidates: candidates)
			state.words[id: id]?.value = .incomplete(text: input, hasFailedValidation: false)
			return .none

		case let .known(.unambiguous(word, match, _)):
			return completeWith(word: word, completion: .auto(match: match), id: id, input: input, &state)

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
		wordCount: BIP39.WordCount,
		language: BIP39.Language
	) -> String {
		precondition(index <= 23, "Invalid BIP39 word index, got index: \(index), exected less than 24.")
		let word: BIP39.Word = {
			let wordList = BIP39.wordList(for: language)
			switch language {
			case .english:
				let bip39Alphabet = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", /* X is missing */ "y", "z"]
				return wordList
					.words
					// we use `last` simply because we did not like the words "abandon baby"
					// which we get by using `first`, too sad a combination.
					.last(
						where: { $0.word.rawValue.hasPrefix(bip39Alphabet[index]) }
					)!

			default:
				let scale = UInt16(89) // 2048 / 23
				let indexScaled = BIP39.Word.Index(valueBoundBy16Bits: scale * UInt16(index))!
				return wordList.indexToWord[indexScaled]!
			}

		}()
		return word.word.rawValue
	}
}

extension ImportMnemonic.Destinations.State {
	fileprivate static func askUserIfSheHasBackedUpMnemonic(_ factorSourceID: FactorSourceID.FromHash) -> Self {
		.markMnemonicAsBackedUp(.init(
			title: { TextState("Confirm Backup") }, // FIXME: Strings
			actions: {
				ButtonState(action: .userHaveBackedUp(factorSourceID), label: { TextState("Yes, I have backed it up") }) // FIXME: Strings
				ButtonState(action: .userHaveNotBackedUp, label: { TextState("No, not yet") }) // FIXME: Strings
			},
			message: { TextState("Are you sure you have securely written down this seed phrase? You will need it to recover access if you lose your phone.") } // FIXME: Strings
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
