// MARK: - OffDeviceMnemonicFactorSourceAccess
@Reducer
struct OffDeviceMnemonicFactorSourceAccess: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let factorSource: OffDeviceMnemonicFactorSource
		var grid: ImportMnemonicGrid.State

		fileprivate var lastSpotCheckFailed = false

		init(factorSource: OffDeviceMnemonicFactorSource) {
			self.factorSource = factorSource
			self.grid = .init(count: factorSource.hint.wordCount)
		}

		var confirmButtonControlState: ControlState {
			if lastSpotCheckFailed {
				return .disabled
			}
			switch status {
			case .incomplete, .invalid:
				return .disabled
			case .readyForSpotCheck:
				return .enabled
			}
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
		case perform(PrivateFactorSource)
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
				return .none
			}
			if state.factorSource.id.spotCheck(input: .software(mnemonicWithPassphrase: mnemonicWithPassphrase)) {
				return .send(.delegate(.perform(.offDeviceMnemonic(state.factorSource, mnemonicWithPassphrase))))
			} else {
				state.lastSpotCheckFailed = true
				return .none
			}
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .grid(.delegate(.didUpdateGrid)):
			state.lastSpotCheckFailed = false
			return .none

		default:
			return .none
		}
	}
}

extension OffDeviceMnemonicFactorSourceAccess.State {
	/// An enum describing the different errors that can take place from user's input.
	enum Status: Sendable, Hashable {
		/// User hasn't entered every word yet.
		case incomplete

		/// User has entered every word but a Mnemonic cannot be built from it (checksum fails).
		case invalid

		/// The entered mnemonic is complete (checksum succeeds), now user needs to tap on Continue
		/// button to perform the spot check.
		case readyForSpotCheck(MnemonicWithPassphrase)
	}

	var status: Status {
		if !isComplete {
			.incomplete
		} else if let mnemonicWithPassphrase {
			.readyForSpotCheck(mnemonicWithPassphrase)
		} else {
			.invalid
		}
	}

	var hint: Hint.ViewState? {
		if lastSpotCheckFailed {
			Hint.ViewState.iconError(L10n.FactorSourceActions.OffDeviceMnemonic.wrong)
		} else if status == .invalid {
			Hint.ViewState.iconError(L10n.FactorSourceActions.OffDeviceMnemonic.invalid)
		} else {
			nil
		}
	}
}

private extension OffDeviceMnemonicFactorSourceAccess.State {
	var mnemonicWithPassphrase: MnemonicWithPassphrase? {
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
