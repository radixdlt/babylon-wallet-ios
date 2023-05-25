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
			case knownAutocompleted(NonEmptyString, fromPartial: String, userPressedCandidateButtonToComplete: Bool)

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
				case let .knownAutocompleted(word, _, _): return word.rawValue
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
		case lostFocus(displayText: String)
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

				case let .knownAutocompleted(_, fromPartial, userPressedCandidateButtonToComplete) where fromPartial != input && userPressedCandidateButtonToComplete:
					// User explicitly chose a candidate to autocomlete
					state.value = .partial(input)

				case let .knownAutocompleted(_, fromPartial, userPressedCandidateButtonToComplete) where fromPartial != input && !userPressedCandidateButtonToComplete:
					// The word was automatically autocompleted, use `fromPartial.dropLast` (since user wanted to erase one char)
					state.value = .partial(.init(fromPartial.dropLast()))

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
			return field == nil ? .send(.delegate(.lostFocus(displayText: state.value.displayText))) : .none
		}
	}
}
