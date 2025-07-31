import ComposableArchitecture
import Sargon

extension AddFactorSource {
	@Reducer
	struct ConfirmSeedPhrase: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			@Shared(.mnemonicBuilder) var mnemonicBuilder
			let factorSourceKind: FactorSourceKind
			var confirmationWords: OrderedDictionary<UInt16, String> = [:]

			var confirmButtonControlState: ControlState {
				let hasEmptyWords = confirmationWords.values.contains(where: \.isEmpty)
				return hasEmptyWords ? .disabled : .enabled
			}

			var focusField: UInt16? = nil
			var wrongWordIndices: Set<UInt16> = []

			init(factorSourceKind: FactorSourceKind) {
				self.factorSourceKind = factorSourceKind

				let indicesOfWordsToConfirm = mnemonicBuilder.getIndicesInMnemonicOfWordsToConfirm()
				self.confirmationWords =
					indicesOfWordsToConfirm.reduce(into: OrderedDictionary<UInt16, String>()) { partialResult, idx in
						partialResult[idx] = ""
					}
			}
		}

		@CasePathable
		enum ViewAction: Sendable, Hashable {
			case confirmButtonTapped
			case wordChanged(index: UInt16, word: String)
			case focusChanged(UInt16?)
			#if DEBUG
			case debugFillTapped
			#endif
		}

		enum DelegateAction: Sendable, Hashable {
			case validated
		}

		typealias Action = FeatureAction<Self>

		var body: some ReducerOf<Self> {
			Reduce(core)
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .confirmButtonTapped:
				state.focusField = nil
				let outcome = state.mnemonicBuilder.validateWords(wordsToConfirm: state.confirmationWords.asDictionary)
				switch outcome {
				case .valid:
					return .send(.delegate(.validated))
				case let .invalid(indicesInMnemonic):
					state.wrongWordIndices = Set(indicesInMnemonic)
					return .none
				}
			case let .focusChanged(idx):
				state.focusField = idx
				return .none

			case let .wordChanged(idx, word):
				state.confirmationWords[idx] = word
				state.wrongWordIndices.remove(idx)

			#if DEBUG
			case .debugFillTapped:
				let seedPhraseWords = state.mnemonicBuilder.getWords()
				for index in state.confirmationWords.keys {
					state.confirmationWords[index] = seedPhraseWords[Int(index)].word
				}
			#endif
			}
			return .none
		}
	}
}
