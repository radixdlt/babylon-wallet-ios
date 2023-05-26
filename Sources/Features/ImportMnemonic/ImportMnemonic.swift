import Cryptography
import FactorSourcesClient
import FeaturePrelude

// MARK: - ImportMnemonic
public struct ImportMnemonic: Sendable, FeatureReducer {
	public static let wordsPerRow = 3

	public struct State: Sendable, Hashable {
		public typealias Words = IdentifiedArrayOf<ImportMnemonicWord.State>
		public var words: Words

		public var idOfWordWithTextFieldFocus: ImportMnemonicWord.State.ID?

		public var language: BIP39.Language
		public var wordCount: BIP39.WordCount {
			willSet {
				let delta = newValue.rawValue - wordCount.rawValue

				if delta > 0 {
					// is increasing word count
					words.append(contentsOf: (wordCount.rawValue ..< newValue.rawValue).map {
						.init(id: $0)
					})
				} else if delta < 0 {
					// is decreasing word count
					words.removeLast(abs(delta))
				}
				switch newValue {
				case .twelve:
					self.isRemoveRowButtonEnabled = false
				case .fifteen, .eighteen, .twentyOne:
					self.isRemoveRowButtonEnabled = true
					self.isAddRowButtonEnabled = true
				case .twentyFour:
					self.isAddRowButtonEnabled = false
				}
			}
		}

		public let wordList: BIP39.WordList

		public var isAddRowButtonEnabled: Bool
		public var isRemoveRowButtonEnabled: Bool

		public var bip39Passphrase: String = ""

		public var mnemonic: Mnemonic? {
			try? Mnemonic(
				words: completedWords
			)
		}

		public var completedWords: [BIP39.Word] {
			words.compactMap(\.completeWord)
		}

		public let saveInProfile: Bool

		public init(
			saveInProfile: Bool,
			language: BIP39.Language = .english,
			wordCount: BIP39.WordCount = .twelve,
			bip39Passphrase: String = ""
		) {
			self.saveInProfile = saveInProfile
			self.wordList = BIP39.wordList(for: language)
			self.language = language
			self.wordCount = wordCount
			self.bip39Passphrase = bip39Passphrase

			self.isAddRowButtonEnabled = wordCount != .twentyFour
			self.isRemoveRowButtonEnabled = wordCount != .twelve

			precondition(wordCount.rawValue.isMultiple(of: ImportMnemonic.wordsPerRow))
			self.words = .init(uncheckedUniqueElements: (0 ..< wordCount.rawValue).map {
				ImportMnemonicWord.State(id: $0)
			})
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case passphraseChanged(String)
		case addRowButtonTapped
		case removeRowButtonTapped

		case continueButtonTapped(Mnemonic)
	}

	public enum InternalAction: Sendable, Equatable {
		case focusNext(ImportMnemonicWord.State.ID)
		case importOlympiaFactorSourceResult(TaskResult<FactorSourceID>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case savedInProfile(FactorSourceID)
		case notSavedInProfile(MnemonicWithPassphrase)
	}

	public enum ChildAction: Sendable, Equatable {
		case word(id: ImportMnemonicWord.State.ID, child: ImportMnemonicWord.Action)
	}

	@Dependency(\.errorQueue) var errorQueue
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

		case let .passphraseChanged(passphrase):
			state.bip39Passphrase = passphrase
			return .none

		case .addRowButtonTapped:
			assert(state.isAddRowButtonEnabled)
			state.wordCount.increaseBy3()
			return .none

		case .removeRowButtonTapped:
			assert(state.isRemoveRowButtonEnabled)
			state.wordCount.decreaseBy3()
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
		state.wordList.lookup(input, minLengthForCandidatesLookup: 2)
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
