import Cryptography
import FactorSourcesClient
import FeaturePrelude
import MnemonicClient
import OverlayWindowClient

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

		public let persistStrategy: PersistStrategy?

		public let isReadonlyMode: Bool
		public let isWordCountFixed: Bool
		public var isAdvancedMode: Bool = false
		public var isHidingSecrets: Bool = false

		public let header: Header?
		public let warning: String?

		#if DEBUG
		public var debugOnlyMnemonicPhraseSingleField = ""
		#endif

		@PresentationState
		public var offDeviceMnemonicInfoPrompt: OffDeviceMnemonicInfo.State?

		public let mnemonicForFactorSourceKind: MnemonicBasedFactorSourceKind

		public enum PersistStrategy: Sendable, Hashable {
			case intoKeychainAndProfile
			case intoKeychainOnly
		}

		public init(
			header: Header? = nil,
			warning: String? = nil,
			isWordCountFixed: Bool = false,
			persistStrategy: PersistStrategy?,
			mnemonicForFactorSourceKind: MnemonicBasedFactorSourceKind,
			language: BIP39.Language = .english,
			wordCount: BIP39.WordCount = .twelve,
			bip39Passphrase: String = "",
			offDeviceMnemonicInfoPrompt: OffDeviceMnemonicInfo.State? = nil
		) {
			precondition(wordCount.rawValue.isMultiple(of: ImportMnemonic.wordsPerRow))

			self.persistStrategy = persistStrategy
			self.mnemonicForFactorSourceKind = mnemonicForFactorSourceKind
			self.language = language
			self.bip39Passphrase = bip39Passphrase

			self.isReadonlyMode = false
			self.isWordCountFixed = isWordCountFixed
			self.words = []
			self.offDeviceMnemonicInfoPrompt = offDeviceMnemonicInfoPrompt
			self.header = header
			self.warning = warning
			changeWordCount(by: wordCount.rawValue)
		}

		public init(
			header: Header? = nil,
			warning: String? = nil,
			mnemonicWithPassphrase: MnemonicWithPassphrase,
			mnemonicForFactorSourceKind: MnemonicBasedFactorSourceKind
		) {
			self.header = header
			self.warning = warning

			let mnemonic = mnemonicWithPassphrase.mnemonic
			self.mnemonicForFactorSourceKind = mnemonicForFactorSourceKind
			self.persistStrategy = nil
			self.language = mnemonic.language
			let isReadonlyMode = true
			self.isReadonlyMode = isReadonlyMode
			self.isWordCountFixed = true
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
		case scenePhase(ScenePhase)

		case toggleModeButtonTapped
		case passphraseChanged(String)
		case addRowButtonTapped
		case removeRowButtonTapped
		case doneViewing
		case continueButtonTapped(Mnemonic)

		#if DEBUG
		case debugOnlyCopyMnemonic
		case debugOnlyMnemonicChanged(String)
		case debugOnlyPasteMnemonic
		#endif
	}

	public enum InternalAction: Sendable, Equatable {
		case focusNext(ImportMnemonicWord.State.ID)
		case saveFactorSourceResult(TaskResult<FactorSource>)
	}

	public enum ChildAction: Sendable, Equatable {
		case offDeviceMnemonicInfoPrompt(PresentationAction<OffDeviceMnemonicInfo.Action>)
		case word(id: ImportMnemonicWord.State.ID, child: ImportMnemonicWord.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case persistedNewFactorSourceInProfile(FactorSource)
		case persistedMnemonicInKeychainOnly(MnemonicWithPassphrase, FactorSourceID.FromHash)
		case doneViewing
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.mnemonicClient) var mnemonicClient
	@Dependency(\.continuousClock) var clock
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	#if DEBUG
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.pasteboardClient) var pasteboardClient
	#endif

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.forEach(\.words, action: /Action.child .. ChildAction.word) {
				ImportMnemonicWord()
			}
			.ifLet(\.$offDeviceMnemonicInfoPrompt, action: /Action.child .. ChildAction.offDeviceMnemonicInfoPrompt) {
				OffDeviceMnemonicInfo()
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

		case let .offDeviceMnemonicInfoPrompt(.presented(.delegate(.done(label, mnemonicWithPassphrase)))):
			state.offDeviceMnemonicInfoPrompt = nil
			precondition(state.mnemonicForFactorSourceKind == .offDevice)
			return .task {
				await .internal(.saveFactorSourceResult(
					TaskResult {
						try await factorSourcesClient.addOffDeviceFactorSource(
							mnemonicWithPassphrase: mnemonicWithPassphrase,
							label: label
						)
					}
				))
			}

		default:
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
			let mnemonicWithPassphrase = MnemonicWithPassphrase(
				mnemonic: mnemonic,
				passphrase: state.bip39Passphrase
			)
			guard let persistStrategy = state.persistStrategy else {
				let factorSourceID = try! FactorSourceID.FromHash(
					kind: state.mnemonicForFactorSourceKind.factorSourceKind,
					mnemonicWithPassphrase: mnemonicWithPassphrase
				)
				return .send(.delegate(.persistedMnemonicInKeychainOnly(mnemonicWithPassphrase, factorSourceID)))
			}

			switch persistStrategy {
			case .intoKeychainAndProfile:
				switch state.mnemonicForFactorSourceKind {
				case .offDevice:
					state.offDeviceMnemonicInfoPrompt = .init(mnemonicWithPassphrase: mnemonicWithPassphrase)
					return .none

				case let .onDevice(onDeviceKind):
					return .task {
						await .internal(.saveFactorSourceResult(
							TaskResult {
								try await factorSourcesClient.addOnDeviceFactorSource(
									onDeviceMnemonicKind: onDeviceKind,
									mnemonicWithPassphrase: mnemonicWithPassphrase
								)
							}
						))
					}
				}
			case .intoKeychainOnly:
				return .task {
					await .internal(.saveFactorSourceResult(
						TaskResult {
							try await factorSourcesClient.addOnDeviceFactorSource(
								onDeviceMnemonicKind: .babylon,
								mnemonicWithPassphrase: mnemonicWithPassphrase,
								saveIntoProfile: false
							)
						}
					))
				}
			}

		case .doneViewing:
			assert(state.isReadonlyMode)
			return .send(.delegate(.doneViewing))

		#if DEBUG
		case .debugOnlyCopyMnemonic:
			if let mnemonic = state.mnemonic?.phrase.rawValue {
				pasteboardClient.copyString(mnemonic)
				overlayWindowClient.scheduleHUD(.init(kind: .copied))
			}
			return .none

		case let .debugOnlyMnemonicChanged(mnemonic):
			state.debugOnlyMnemonicPhraseSingleField = mnemonic
			if let mnemonic = try? Mnemonic(phrase: mnemonic, language: state.language) {
				return .send(.view(.continueButtonTapped(mnemonic)))
			} else {
				return .none
			}

		case .debugOnlyPasteMnemonic:
			let toPaste = pasteboardClient.getString() ?? ""
			return .send(.view(.debugOnlyMnemonicChanged(toPaste)))
		#endif
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .focusNext(id):
			state.idOfWordWithTextFieldFocus = id
			state.words[id: id]?.focus()
			return .none

		case let .saveFactorSourceResult(.failure(error)):
			errorQueue.schedule(error)
			loggerGlobal.error("Failed to save mnemonic in profile, error: \(error)")
			return .none

		case let .saveFactorSourceResult(.success(factorSource)):
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
