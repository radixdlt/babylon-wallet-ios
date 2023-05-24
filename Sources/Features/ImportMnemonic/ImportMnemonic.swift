import Cryptography
import FeaturePrelude

// MARK: - ImportMnemonicWord
public struct ImportMnemonicWord: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public enum Field: Hashable {
			case textField
		}

		public enum WordValue: Sendable, Hashable {
			case partial(String = "")
			case invalid(String)
			case knownFull(NonEmptyString, fromPartial: String)
			case knownAutocompleted(NonEmptyString, fromPartial: String)

			var isValid: Bool {
				switch self {
				case .knownFull, .knownAutocompleted: return true
				case .partial, .invalid: return false
				}
			}

			var isInvalid: Bool {
				guard case .invalid = self else {
					return false
				}
				return true
			}

			var displayText: String {
				switch self {
				case let .invalid(text): return text
				case let .partial(text): return text
				case let .knownFull(word, _): return word.rawValue
				case let .knownAutocompleted(word, _): return word.rawValue
				}
			}
		}

		public struct AutocompletionCandidates: Sendable, Hashable {
			public let input: String
			public let candidates: OrderedSet<NonEmptyString>
		}

		public typealias ID = Int
		public let id: ID
		public var value: WordValue
		public var autocompletionCandidates: AutocompletionCandidates? = nil
		public var focusedField: Field? = nil
		public init(id: ID, value: WordValue = .partial()) {
			self.id = id
			self.value = value
		}

		public var isValidWord: Bool {
			value.isValid
		}

		public mutating func focus() {
			self.focusedField = .textField
		}

		public mutating func resignFocus() {
			self.focusedField = nil
		}
	}

	public enum ViewAction: Sendable, Hashable {
		case wordChanged(input: String)
		case autocompleteWith(candidate: NonEmptyString)
		case textFieldFocused(State.Field?)
	}

	public enum DelegateAction: Sendable, Hashable {
		case lookupWord(input: String)
		case autocompleteWith(candidate: NonEmptyString, fromPartial: String)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .wordChanged(input):
			guard input.count >= state.value.displayText.count else {
				// We dont perform lookup when we decrease character count
				switch state.value {
				case .invalid, .partial:
					state.value = .partial(input)
				case let .knownAutocompleted(_, fromPartial) where fromPartial != input:
					state.value = .partial(input)
				case let .knownFull(_, fromPartial) where fromPartial != input:
					state.value = .partial(input)
				default: break
				}
				return .none
			}
			return .send(.delegate(.lookupWord(input: input)))

		case let .autocompleteWith(candidate):
			return .send(.delegate(.autocompleteWith(
				candidate: candidate,
				fromPartial: state.value.displayText
			)))
		case let .textFieldFocused(field):
			state.focusedField = field
			return .none
		}
	}
}

// MARK: - BIP39.WordList + Sendable
extension BIP39.WordList: @unchecked Sendable {}
let wordsPerRow = 3

// MARK: - ImportMnemonic
public struct ImportMnemonic: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public typealias Words = IdentifiedArrayOf<ImportMnemonicWord.State>
		public var words: Words

		public var rowCount: Int {
			words.count / wordsPerRow
		}

		public var idOfWordWithTextFieldFocus: ImportMnemonicWord.State.ID? {
			mutating willSet {
				if let newValue {
					words[id: newValue]?.focus()
				}
			}
		}

		public var language: BIP39.Language
		public var wordCount: BIP39.WordCount
		public let wordList: BIP39.WordList

		public init(
			language: BIP39.Language = .english,
			wordCount: BIP39.WordCount = .twelve
		) {
			self.wordList = BIP39.wordList(for: language)
			self.language = language
			self.wordCount = wordCount
			precondition(wordCount.rawValue.isMultiple(of: wordsPerRow))
			#if DEBUG
			self.words = .init(
				uncheckedUniqueElements: [
					"position",
					"possible",
					"REPLACEME",
					"priority",
					"property",
					"purchase",
					"question",
					"remember",
					"resemble",
					"resource",
					"response",
					"scissors",
					"scorpion",
					"security",
					"sentence",
					"shoulder",
					"solution",
					"squirrel",
					"strategy",
					"struggle",
					"surprise",
					"surround",
					"together",
					"tomorrow",
				]
				.enumerated()
				.map {
					ImportMnemonicWord.State(
						id: $0.offset,
						value: .knownFull(NonEmptyString(rawValue: $0.element)!, fromPartial: $0.element)
					)
				}
			)

			words[id: 2]?.value = .invalid("Ultrasuperlong")
			#else
			self.words = .init(uncheckedUniqueElements: (0 ..< wordCount.rawValue).map {
				ImportMnemonicWord.State(id: $0)
			})
			#endif
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case continueButtonTapped(Mnemonic)
	}

	public enum InternalAction: Sendable, Equatable {
		case focusNext(ImportMnemonicWord.State.ID)
	}

	public enum DelegateAction: Sendable, Equatable {
		case finishedInputtingMnemonic(Mnemonic)
	}

	public enum ChildAction: Sendable, Equatable {
		case word(id: ImportMnemonicWord.State.ID, child: ImportMnemonicWord.Action)
	}

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
			let lookedUp = state.wordList.lookup(input, minLengthForPartial: 2, ignoreCandidateIfCountExceeds: 5)
			print("🔮: \(lookedUp)")
			return updateWord(id: id, input: input, &state, lookupResult: lookedUp)

		case let .word(id, child: .delegate(.autocompleteWith(candidate, input))):
			return updateWord(id: id, input: input, &state, lookupResult: .knownFull(candidate))

		case .word(_, child: .view), .word(_, child: .internal):
			return .none
		}
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
			state.words[id: id]?.autocompletionCandidates = nil
			state.words[id: id]?.value = .partial(input)
			return .none

		case let .knownFull(knownFull):
			state.words[id: id]?.autocompletionCandidates = nil
			state.words[id: id]?.value = .knownFull(knownFull, fromPartial: input)
			return focusNext(&state)

		case let .knownAutocomplete(knownAutocomplete):
			state.words[id: id]?.autocompletionCandidates = nil
			state.words[id: id]?.value = .knownAutocompleted(knownAutocomplete, fromPartial: input)
			return focusNext(&state)
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return focusNext(&state)

		case let .continueButtonTapped(mnemonic):
			return .send(.delegate(.finishedInputtingMnemonic(mnemonic)))
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .focusNext(id):
			state.idOfWordWithTextFieldFocus = id
			return .none
		}
	}

	func focusNext(_ state: inout State) -> EffectTask<Action> {
		if let current = state.idOfWordWithTextFieldFocus {
			state.words[id: current]?.resignFocus()
		}
		guard let nextID = state.words.first(where: { !$0.isValidWord })?.id else {
			return .none
		}

		return .run { send in
			try? await Task.sleep(for: .milliseconds(200))
			await send(.internal(.focusNext(nextID)))
		}
	}
}
