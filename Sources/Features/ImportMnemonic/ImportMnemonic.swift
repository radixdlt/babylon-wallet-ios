import Cryptography
import FeaturePrelude

// MARK: - BIP39.WordList + Sendable
extension BIP39.WordList: @unchecked Sendable {}
let wordsPerRow = 3

// MARK: - BIP39.WordCount + Comparable
extension BIP39.WordCount: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.rawValue < rhs.rawValue
	}

	mutating func increaseBy3() {
		guard self != .twentyFour else {
			assertionFailure("Invalid, cannot increase to than 24 words")
			return
		}
		self = .init(rawValue: rawValue + 3)!
	}

	mutating func decreaseBy3() {
		guard self != .twelve else {
			assertionFailure("Invalid, cannot decrease to less than 12 words")
			return
		}
		self = .init(rawValue: rawValue - 3)!
	}
}

// MARK: - ImportMnemonic
public struct ImportMnemonic: Sendable, FeatureReducer {
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
				words: words.map(\.value.displayText),
				language: language
			)
		}

		public init(
			language: BIP39.Language = .english,
			wordCount: BIP39.WordCount = .twelve,
			bip39Passphrase: String = ""
		) {
			self.wordList = BIP39.wordList(for: language)
			self.language = language
			self.wordCount = wordCount
			self.bip39Passphrase = bip39Passphrase

			self.isAddRowButtonEnabled = wordCount != .twentyFour
			self.isRemoveRowButtonEnabled = wordCount != .twelve

			precondition(wordCount.rawValue.isMultiple(of: wordsPerRow))
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
	}

	public enum DelegateAction: Sendable, Equatable {
		case finishedInputtingMnemonicWithPassphrase(MnemonicWithPassphrase)
	}

	public enum ChildAction: Sendable, Equatable {
		case word(id: ImportMnemonicWord.State.ID, child: ImportMnemonicWord.Action)
	}

	@Dependency(\.continuousClock) var clock

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
			case .invalid, .partialAmongstCandidates:
				break // => perform validation
			case .knownAutocomplete, .knownFull, .emptyOrTooShort:
				return .none
			}

			return updateWord(id: id, input: displayText, &state, lookupResult: .invalid)

		case let .word(id, child: .delegate(.autocompleteWith(candidate, input))):
			return autocompleteWithCandidate(id: id, input: input, &state, word: candidate, userPressedCandidateButtonToComplete: true)

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
			return .send(.delegate(.finishedInputtingMnemonicWithPassphrase(mnemonicWithPassphrase)))
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .focusNext(id):
			state.idOfWordWithTextFieldFocus = id
			state.words[id: id]?.focus()
			return .none
		}
	}
}

extension ImportMnemonic {
	private func lookup(input: String, _ state: State) -> BIP39.WordList.LookupResult {
		state.wordList.lookup(input, minLengthForPartial: 2, ignoreCandidateIfCountExceeds: 5)
	}

	private func autocompleteWithCandidate(
		id: ImportMnemonicWord.State.ID,
		input: String,
		_ state: inout State,
		word: NonEmptyString,
		userPressedCandidateButtonToComplete: Bool
	) -> EffectTask<Action> {
		switch state.words[id: id]?.value {
		case let .some(.partial(partial)):
			guard abs(input.count - partial.count) <= 1 else {
				// It is unfortunate that this is needed, perhaps just needed due to nature of current implementation... so here is what is going on:
				// We do this to support a very special corner case where user has inputted e.g. "ret" and then "r" => "retr" which gets autocompleted
				// into "retret", and the next field is focused. She realize the last "r" was a mistake, it is not "retret" she wanted to input, but
				// actually e.g. "return", so she refocuses the textfield and presses erase keyboard button. Now the current implementation is smart!
				// we do not change the **displayed** word from "retreat" => "retrea", rather we have saved that user had originally only inputted
				// "retr" so what we WANT the textfield to change into is "ret", which we have logic for in `ImportMnemonicWord` reducer
				// (search for "dropLast()"), however, due to SwiftUI... what happens is that **immediately** after "ret" is set as text on the
				// TextField, a subsequent event is emitted from TextField `text` binding with the value "retrea", which overrides what we **just**
				// had accomplished (replaced with "ret"). Luckily we can prevent this, by guarding that the character limit is only `1` char,
				// and not in this case `3` (`"retrea".count - "ret".count`)
				return .none
			}
		default: break
		}

		state.words[id: id]?.value = .knownAutocompleted(word, fromPartial: input, userPressedCandidateButtonToComplete: userPressedCandidateButtonToComplete)
		return focusNext(&state)
	}

	private func updateWord(
		id: ImportMnemonicWord.State.ID,
		input: String,
		_ state: inout State,
		lookupResult: BIP39.WordList.LookupResult
	) -> EffectTask<Action> {
		switch lookupResult {
		case let .partialAmongstCandidates(candidates):
			state.words[id: id]?.autocompletionCandidates = .init(input: input, candidates: candidates)
			state.words[id: id]?.value = .partial(input)
			return .none

		case .emptyOrTooShort:
			state.words[id: id]?.value = .partial(input)
			return .none

		case let .knownFull(knownFull):
			state.words[id: id]?.value = .knownFull(knownFull, fromPartial: input)
			return focusNext(&state)

		case let .knownAutocomplete(knownAutocomplete):
			return autocompleteWithCandidate(id: id, input: input, &state, word: knownAutocomplete, userPressedCandidateButtonToComplete: false)

		case .invalid:
			state.words[id: id]?.value = .invalid(input)
			return .none
		}
	}

	private func focusNext(_ state: inout State) -> EffectTask<Action> {
		if let current = state.idOfWordWithTextFieldFocus {
			state.words[id: current]?.resignFocus()
		}
		guard let nextID = state.words.first(where: { !$0.isValidWord })?.id else {
			return .none
		}

		return .run { send in
			try? await clock.sleep(for: .milliseconds(75))
			await send(.internal(.focusNext(nextID)))
		}
	}
}
