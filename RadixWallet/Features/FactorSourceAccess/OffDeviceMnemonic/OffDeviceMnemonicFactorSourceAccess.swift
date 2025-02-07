// MARK: - OffDeviceMnemonicFactorSourceAccess
@Reducer
struct OffDeviceMnemonicFactorSourceAccess: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let factorSource: OffDeviceMnemonicFactorSource
		var grid: ImportMnemonicGrid.State
		var showError = false

		init(factorSource: OffDeviceMnemonicFactorSource) {
			self.factorSource = factorSource
			self.grid = .init(count: factorSource.hint.wordCount, isWordCountFixed: true)
		}

		var confirmButtonControlState: ControlState {
			!isComplete || showError ? .disabled : .enabled
		}
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Hashable {
		case confirmButtonTapped
	}

	@CasePathable
	enum ChildAction: Sendable, Hashable {
		case grid(ImportMnemonicGrid.Action)
	}

	enum DelegateAction: Sendable, Hashable {
		case perform(FactorSourcePerformer)
	}

	var body: some ReducerOf<Self> {
		Scope(state: \.grid, action: \.child.grid) {
			ImportMnemonicGrid()
		}
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .confirmButtonTapped:
			guard let mnemonicWithPassphrase = state.mnemonicWithPassphrase else {
				state.showError = true
				return .none
			}
			if state.factorSource.id.spotCheck(input: .software(mnemonicWithPassphrase: mnemonicWithPassphrase)) {
				return .send(.delegate(.perform(.offDeviceMnemonic(mnemonicWithPassphrase, state.factorSource))))
			} else {
				state.showError = true
				return .none
			}
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .grid(.delegate(.didUpdateGrid)):
			state.showError = false
			return .none

		default:
			return .none
		}
	}
}

private extension OffDeviceMnemonicFactorSourceAccess.State {
	var mnemonicWithPassphrase: MnemonicWithPassphrase? {
		let completedWords = self.completedWords
		let expectedCount = Int(factorSource.hint.wordCount.rawValue)
		guard completedWords.count == expectedCount else {
			// Verify it is complete
			return nil
		}
		guard let mnemonic = try? Mnemonic(words: completedWords) else {
			return nil
		}
		return .init(mnemonic: mnemonic)
	}

	var isComplete: Bool {
		completedWords.count == grid.words.count
	}

	var completedWords: [BIP39Word] {
		grid.words.compactMap(\.completeWord)
	}
}
