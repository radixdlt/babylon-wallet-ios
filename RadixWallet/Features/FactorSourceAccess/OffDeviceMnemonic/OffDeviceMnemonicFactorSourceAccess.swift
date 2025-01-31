// MARK: - OffDeviceMnemonicFactorSourceAccess
@Reducer
struct OffDeviceMnemonicFactorSourceAccess: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let factorSource: OffDeviceMnemonicFactorSource
		var grid: ImportMnemonicGrid.State

		init(factorSource: OffDeviceMnemonicFactorSource) {
			self.factorSource = factorSource
			self.grid = .init(count: factorSource.hint.wordCount, isWordCountFixed: true)
		}

		var confirmButtonControlState: ControlState {
			isComplete ? .enabled : .disabled
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

	var body: some ReducerOf<Self> {
		Scope(state: \.grid, action: \.child.grid) {
			ImportMnemonicGrid()
		}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .confirmButtonTapped:
			.none
		}
	}
}

private extension OffDeviceMnemonicFactorSourceAccess.State {
	var mnemonic: Mnemonic? {
		guard isComplete else {
			return nil
		}
		return try? Mnemonic(words: completedWords)
	}

	var isComplete: Bool {
		completedWords.count == grid.words.count
	}

	var completedWords: [BIP39Word] {
		grid.words.compactMap(\.completeWord)
	}
}
