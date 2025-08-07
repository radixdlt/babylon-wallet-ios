// MARK: - ArculusForgotPIN
enum ArculusForgotPIN {}

// MARK: ArculusForgotPIN.InputSeedPhrase
extension ArculusForgotPIN {
	// MARK: - ArculusForgotPIN-InputSeedPhrase
	@Reducer
	struct InputSeedPhrase: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			let factorSource: ArculusCardFactorSource

			var grid: ImportMnemonicGrid.State = .init(count: .twentyFour, wordCounts: [.twelve, .twentyFour])

			var validationStatus: ImportMnemonicGrid.State.MnemonicValidationStatus {
				grid.mnemonicValidationStatus(factorSource.asGeneral)
			}

			var mnemonicHint: Hint.ViewState? {
				switch validationStatus {
				case .incomplete, .correct:
					nil
				case .invalid:
					Hint.ViewState.iconError(L10n.FactorSourceActions.OffDeviceMnemonic.invalid)
				case .wrong:
					Hint.ViewState.iconError(L10n.FactorSourceActions.OffDeviceMnemonic.wrong)
				}
			}

			var mnemonic: Mnemonic? {
				switch validationStatus {
				case .incomplete, .invalid, .wrong:
					nil
				case .correct:
					grid.mnemonicWithPassphrase!.mnemonic
				}
			}

			@Presents
			var destination: Destination.State?
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case confirmButtonTapped(Mnemonic)
		}

		@CasePathable
		enum ChildAction: Sendable, Hashable {
			case grid(ImportMnemonicGrid.Action)
		}

		enum DelegateAction: Sendable, Hashable {
			case finished
		}

		struct Destination: DestinationReducer {
			@CasePathable
			enum State: Sendable, Hashable {
				case configureNewPIN(ArculusForgotPIN.EnterNewPIN.State)
			}

			@CasePathable
			enum Action: Sendable, Equatable {
				case configureNewPIN(ArculusForgotPIN.EnterNewPIN.Action)
			}

			var body: some ReducerOf<Self> {
				Scope(state: \.configureNewPIN, action: \.configureNewPIN) {
					ArculusForgotPIN.EnterNewPIN()
				}
			}
		}

		private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

		var body: some ReducerOf<Self> {
			Scope(state: \.grid, action: \.child.grid) {
				ImportMnemonicGrid()
			}

			Reduce(core)
				.ifLet(destinationPath, action: \.destination) {
					Destination()
				}
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case let .confirmButtonTapped(mnemonic):
				state.destination = .configureNewPIN(.init(mnemonic: mnemonic))
				return .none
			}
		}

		func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
			switch presentedAction {
			case .configureNewPIN(.delegate(.finished)):
				.send(.delegate(.finished))
			default:
				.none
			}
		}
	}
}

extension ImportMnemonicGrid.State {
	/// An enum describing the different errors that can take place from user's input.
	enum MnemonicValidationStatus: Sendable, Hashable {
		/// User hasn't entered every word yet.
		case incomplete

		/// User has entered every word but a Mnemonic cannot be built from it (checksum fails).
		case invalid

		/// The entered mnemonic is complete (checksum succeeds), but it does not match the the target factor source id
		case wrong

		/// The entered mnemonic is complete (checksum succeeds), and  it does match the the target factor source id
		case correct
	}

	func mnemonicValidationStatus(_ fs: FactorSource) -> MnemonicValidationStatus {
		switch status {
		case .incomplete:
			.incomplete
		case .invalid:
			.invalid
		case let .valid(mwp):
			FactorSourceIdFromHash(kind: fs.kind, mnemonicWithPassphrase: mwp).asGeneral == fs.factorSourceID ? .correct : .wrong
		}
	}
}
