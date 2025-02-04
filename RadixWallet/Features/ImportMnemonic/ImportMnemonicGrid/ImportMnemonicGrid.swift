// MARK: - ImportMnemonicGrid
@Reducer
struct ImportMnemonicGrid: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		typealias Words = IdentifiedArrayOf<ImportMnemonicWord.State>

		var words: Words
		let language: BIP39Language
		let isWordCountFixed: Bool
		let isReadOnlyMode: Bool

		init(
			count: Bip39WordCount,
			language: BIP39Language = .english,
			isWordCountFixed: Bool
		) {
			self.words = []
			self.language = language
			self.isWordCountFixed = isWordCountFixed
			self.isReadOnlyMode = false

			changeWordCount(to: count)
		}

		init(mnemonic: Mnemonic) {
			self.words = Self.words(from: mnemonic, isReadOnlyMode: true)
			self.language = mnemonic.language
			self.isWordCountFixed = true
			self.isReadOnlyMode = true
		}

		var wordCount: BIP39WordCount {
			BIP39WordCount(wordCount: words.count) ?? .twentyFour
		}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Sendable, Hashable {
		case appeared
		case wordCountChanged(BIP39WordCount)

		#if DEBUG
		case debugCopy
		case debugPaste
		case debugSetSample
		#endif
	}

	enum InternalAction: Sendable, Hashable {
		case focusOn(ImportMnemonicWord.State.ID)
	}

	@CasePathable
	enum ChildAction: Sendable, Hashable {
		case word(ImportMnemonicWord.State.ID, ImportMnemonicWord.Action)
	}

	enum DelegateAction: Sendable, Hashable {
		case didUpdateGrid
	}

	@Dependency(\.mnemonicClient) var mnemonicClient
	#if DEBUG
	@Dependency(\.pasteboardClient) var pasteboardClient
	#endif

	var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.words, action: /Action.child .. ChildAction.word) {
				ImportMnemonicWord()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return focusNext(&state, after: nil)

		case let .wordCountChanged(value):
			state.changeWordCount(to: value)
			return .none

		#if DEBUG
		case .debugCopy:
			let phrase = state.words.compactMap(\.completeWord?.word).joined(separator: " ")
			pasteboardClient.copyString(phrase)
			return .none

		case .debugPaste:
			if let phrase = pasteboardClient.getString(), let mnemonic = try? Mnemonic(phrase: phrase, language: state.language) {
				state.words = State.words(from: mnemonic, isReadOnlyMode: state.isReadOnlyMode)
			}
			return .none

		case .debugSetSample:
			state.words = State.words(from: .sampleDevice, isReadOnlyMode: state.isReadOnlyMode)
			return .none
		#endif
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .focusOn(id):
			state.words[id: id]?.focus()
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .word(id, .delegate(.lookupWord(input))):
			let lookUpResult = lookup(input: input, state)
			return updateWord(id: id, input: input, &state, lookupResult: lookUpResult)

		case let .word(id, .delegate(.lostFocus(displayText))):
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

		case let .word(id, .delegate(.userSelectedCandidate(candidate, input))):
			return completeWith(
				word: candidate,
				completion: .user,
				id: id,
				input: input,
				&state
			)

		case let .word(id, .delegate(.didSubmit)):
			return focusNext(&state, after: id)

		default:
			return .none
		}
	}
}

private extension ImportMnemonicGrid {
	func lookup(input: String, _ state: State) -> BIP39LookupResult {
		mnemonicClient.lookup(.init(
			language: state.language,
			input: input,
			minLenghForCandidatesLookup: 2
		))
	}

	func completeWith(
		word: BIP39Word,
		completion: ImportMnemonicWord.State.WordValue.Completion,
		id: ImportMnemonicWord.State.ID,
		input: String,
		_ state: inout State
	) -> Effect<Action> {
		state.words[id: id]?.value = .complete(text: input, word: word, completion: completion)
		return notifyUpdate()
	}

	func updateWord(
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
			guard let userInput = candidates.first(where: { $0.word == nonEmptyInput.rawValue }) else {
				state.words[id: id]?.value = .incomplete(text: input, hasFailedValidation: false)
				return notifyUpdate()
			}

			return completeWith(word: userInput, completion: .user, id: id, input: input, &state)

		case let .known(.unambiguous(word, _, _)):
			guard word.word == input else {
				state.words[id: id]?.value = .incomplete(text: input, hasFailedValidation: false)
				return notifyUpdate()
			}
			return completeWith(word: word, completion: .user, id: id, input: input, &state)

		case .unknown(.notInList):
			state.words[id: id]?.value = .incomplete(text: input, hasFailedValidation: true)
			return notifyUpdate()

		case .unknown(.tooShort):
			state.words[id: id]?.value = .incomplete(text: input, hasFailedValidation: false)
			return notifyUpdate()
		}
	}

	func focusNext(_ state: inout State, after current: Int?) -> Effect<Action> {
		if let current {
			state.words[id: current]?.resignFocus()
			return delayedEffect(delay: .milliseconds(75), for: .internal(.focusOn(current + 1)))
		} else if let firstIncomplete = state.words.first(where: { !$0.isComplete })?.id {
			return delayedEffect(delay: .milliseconds(75), for: .internal(.focusOn(firstIncomplete)))
		} else {
			return .none
		}
	}

	func notifyUpdate() -> Effect<Action> {
		.send(.delegate(.didUpdateGrid))
	}
}

private extension ImportMnemonicGrid.State {
	mutating func changeWordCount(to newWordCount: BIP39WordCount) {
		let wordCount = words.count
		let delta = Int(newWordCount.rawValue) - wordCount
		if delta > 0 {
			// is increasing word count
			words.append(contentsOf: (wordCount ..< Int(newWordCount.rawValue)).map {
				.init(
					id: $0,
					isReadonlyMode: isReadOnlyMode
				)
			})
		} else if delta < 0 {
			// is decreasing word count
			words.removeLast(-delta)
		}
	}

	static func words(from mnemonic: Mnemonic, isReadOnlyMode: Bool) -> Words {
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
						isReadonlyMode: isReadOnlyMode
					)
				}
		)
	}
}
