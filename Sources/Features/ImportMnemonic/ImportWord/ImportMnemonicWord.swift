import Cryptography
import FeaturePrelude

// MARK: - ImportMnemonicWord
public struct ImportMnemonicWord: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public enum Field: Hashable, Sendable {
			case textField
		}

		public enum WordValue: Sendable, Hashable {
			case incomplete(
				text: String,
				hasFailedValidation: Bool
			)

			case complete(
				text: NonEmptyString,
				word: BIP39.Word,
				match: BIP39.WordList.LookupResult.Known.UnambiguousMatch,
				completion: Completion
			)

			public enum Completion: String, Sendable, Hashable {
				/// We automatically completed the word, since it was unambigiously identified as a BIP39 word.
				case auto

				/// User explicitly chose the word from a list of candidates.
				case user
			}

			var isComplete: Bool {
				switch self {
				case .complete: return true
				case .incomplete: return false
				}
			}

			var hasFailedValidation: Bool {
				guard case let .incomplete(_, hasFailedValidation) = self else {
					return false
				}
				return hasFailedValidation
			}

			var text: String {
				switch self {
				case let .complete(_, word, _, _):
					return word.word.rawValue
				case let .incomplete(text, _):
					return text
				}
			}
		}

		public struct AutocompletionCandidates: Sendable, Hashable {
			public let input: NonEmptyString
			public let candidates: NonEmpty<OrderedSet<BIP39.Word>>
		}

		public typealias ID = Int
		public let id: ID
		public var value: WordValue

		public var autocompletionCandidates: AutocompletionCandidates? = nil
		public var focusedField: Field? = nil

		public init(
			id: ID,
			value: WordValue = .incomplete(text: "", hasFailedValidation: false)
		) {
			self.id = id
			self.value = value
		}

		public var isComplete: Bool {
			value.isComplete
		}

		public var completeWord: BIP39.Word? {
			guard case let .complete(_, word, _, _) = value else {
				return nil
			}
			return word
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
		case userSelectedCandidate(BIP39.Word)
		case textFieldFocused(State.Field?)
	}

	public enum DelegateAction: Sendable, Hashable {
		case lookupWord(input: String)
		case lostFocus(displayText: String)
		case userSelectedCandidate(BIP39.Word, fromPartial: String)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .wordChanged(input):
			guard input.count >= state.value.text.count else {
				// We dont perform lookup when we decrease character count
				switch state.value {
				case .incomplete:
					state.value = .incomplete(text: input, hasFailedValidation: false)

				case let .complete(fromPartial, _, match: .startsWith, completion: .user) where fromPartial.rawValue != input:
					// User explicitly chose a candidate to autocomlete
					state.value = .incomplete(text: input, hasFailedValidation: false)

				case let .complete(fromPartial, _, match: .startsWith, completion: .auto) where fromPartial.rawValue != input:
					// The word was automatically autocompleted, use `fromPartial.dropLast` (since user wanted to erase one char)
					state.value = .incomplete(text: .init(fromPartial.rawValue.dropLast()), hasFailedValidation: false)

				case let .complete(fromPartial, _, match: .exact, completion: .auto) where fromPartial.rawValue != input:
					state.value = .incomplete(text: input, hasFailedValidation: false)

				default:
					break
				}
				return .none
			}

			return .send(.delegate(.lookupWord(input: input)))

		case let .userSelectedCandidate(candidate):
			return .send(.delegate(.userSelectedCandidate(
				candidate,
				fromPartial: state.value.text
			)))
		case let .textFieldFocused(field):
			state.focusedField = field
			return field == nil ? .send(.delegate(.lostFocus(displayText: state.value.text))) : .none
		}
	}
}
