import Cryptography
import FactorSourcesClient
import FeaturePrelude
import MnemonicClient

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
			let newWordCount = BIP39.WordCount(wordCount: wordCount + delta)! // might infact be subtraction
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
						isReadonlyMode: isReadonlyMode
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

		public let saveInProfile: Bool

		public let isReadonlyMode: Bool
		public var isHidingSecrets: Bool = false

		public init(
			saveInProfile: Bool,
			language: BIP39.Language = .english,
			wordCount: BIP39.WordCount = .twelve,
			bip39Passphrase: String = ""
		) {
			precondition(wordCount.rawValue.isMultiple(of: ImportMnemonic.wordsPerRow))

			self.saveInProfile = saveInProfile
			self.language = language
			self.bip39Passphrase = bip39Passphrase

			let isReadonlyMode = false
			self.isReadonlyMode = isReadonlyMode
			self.words = []
			changeWordCount(by: wordCount.rawValue)
		}

		public init(
			mnemonicWithPassphrase: MnemonicWithPassphrase
		) {
			let mnemonic = mnemonicWithPassphrase.mnemonic
			self.saveInProfile = false
			self.language = mnemonic.language
			let isReadonlyMode = true
			self.isReadonlyMode = isReadonlyMode
			self.words = .init(
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
			self.bip39Passphrase = mnemonicWithPassphrase.passphrase
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case scenePhase(ScenePhase)

		case passphraseChanged(String)
		case addRowButtonTapped
		case removeRowButtonTapped
		case doneViewing
		case continueButtonTapped(Mnemonic)
	}

	public enum InternalAction: Sendable, Equatable {
		case focusNext(ImportMnemonicWord.State.ID)
		case importOlympiaFactorSourceResult(TaskResult<FactorSourceID>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case savedInProfile(FactorSourceID)
		case notSavedInProfile(MnemonicWithPassphrase)
		case doneViewing
	}

	public enum ChildAction: Sendable, Equatable {
		case word(id: ImportMnemonicWord.State.ID, child: ImportMnemonicWord.Action)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.mnemonicClient) var mnemonicClient
	@Dependency(\.continuousClock) var clock
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.forEach(\.words, action: /Action.child .. ChildAction.word) {
				ImportMnemonicWord()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .word(id, child: .delegate(.lookupWord(input))):
			let lookUpResult = lookup(input: input, state)
			return updateWord(id: id, input: input, &state, lookupResult: lookUpResult)

		case let .word(id, child: .delegate(.lostFocus(displayText))):
			switch lookup(input: displayText, state) {
			case .known(.ambigous), .unknown(.notInList):
				state.words[id: id]?.value = .incomplete(text: displayText, hasFailedValidation: true)
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

		case .word(_, child: .view), .word(_, child: .internal):
			return .none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return focusNext(&state)

		case .scenePhase(.background), .scenePhase(.inactive):
			state.isHidingSecrets = true
			return .none

		case .scenePhase(.active), .scenePhase:
			state.isHidingSecrets = false
			return .none

		case let .passphraseChanged(passphrase):
			state.bip39Passphrase = passphrase
			return .none

		case .addRowButtonTapped:
			state.changeWordCount(by: +ImportMnemonic.wordsPerRow)
			return .none

		case .removeRowButtonTapped:
			state.changeWordCount(by: -ImportMnemonic.wordsPerRow)
			return .none

		case let .continueButtonTapped(mnemonic):
			let mnemonicWithPassphrase = MnemonicWithPassphrase(
				mnemonic: mnemonic,
				passphrase: state.bip39Passphrase
			)
			guard state.saveInProfile else {
				return .send(.delegate(.notSavedInProfile(mnemonicWithPassphrase)))
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

		case .doneViewing:
			assert(state.isReadonlyMode)
			return .send(.delegate(.doneViewing))
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .focusNext(id):
			state.idOfWordWithTextFieldFocus = id
			state.words[id: id]?.focus()
			return .none

		case let .importOlympiaFactorSourceResult(.failure(error)):
			errorQueue.schedule(error)
			loggerGlobal.error("Failed to save mnemonic in profile, error: \(error)")
			return .none

		case let .importOlympiaFactorSourceResult(.success(factorSourceID)):
			return .send(.delegate(.savedInProfile(factorSourceID)))
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
	) -> EffectTask<Action> {
		state.words[id: id]?.value = .complete(text: input, word: word, completion: completion)
		return focusNext(&state)
	}

	private func updateWord(
		id: ImportMnemonicWord.State.ID,
		input: String,
		_ state: inout State,
		lookupResult: BIP39.WordList.LookupResult
	) -> EffectTask<Action> {
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

	private func focusNext(_ state: inout State) -> EffectTask<Action> {
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

// MARK: - ScenePhase + Sendable
extension ScenePhase: @unchecked Sendable {}
