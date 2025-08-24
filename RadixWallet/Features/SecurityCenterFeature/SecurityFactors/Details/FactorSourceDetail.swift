// MARK: - FactorSourceDetail
@Reducer
struct FactorSourceDetail: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var integrity: FactorSourceIntegrity
		var name: String
		var lastUsed: Timestamp

		init(integrity: FactorSourceIntegrity) {
			self.integrity = integrity
			self.name = integrity.factorSource.asGeneral.name
			self.lastUsed = integrity.factorSource.asGeneral.common.lastUsedOn
		}

		@Presents
		var destination: Destination.State?

		var factorSource: FactorSource {
			integrity.factorSource
		}
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case renameTapped
		case viewSeedPhraseTapped
		case enterSeedPhraseTapped
		case changePinTapped
		case forgotPinTapped
		// case spotCheckTapped
	}

	enum InternalAction: Sendable, Hashable {
		case integrityUpdated(FactorSourceIntegrity)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case rename(RenameLabel.State)
			case displayMnemonic(DisplayMnemonic.State)
			case importMnemonic(ImportMnemonicForFactorSource.State)
			case arculusUpdatePIN(ArculusChangePIN.EnterOldPIN.State)
			case arculusForgotPIN(ArculusForgotPIN.InputSeedPhrase.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case rename(RenameLabel.Action)
			case displayMnemonic(DisplayMnemonic.Action)
			case importMnemonic(ImportMnemonicForFactorSource.Action)
			case arculusUpdatePIN(ArculusChangePIN.EnterOldPIN.Action)
			case arculusForgotPIN(ArculusForgotPIN.InputSeedPhrase.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.rename, action: \.rename) {
				RenameLabel()
			}
			Scope(state: \.displayMnemonic, action: \.displayMnemonic) {
				DisplayMnemonic()
			}
			Scope(state: \.importMnemonic, action: \.importMnemonic) {
				ImportMnemonicForFactorSource()
			}
			Scope(state: \.arculusUpdatePIN, action: \.arculusUpdatePIN) {
				ArculusChangePIN.EnterOldPIN()
			}
			Scope(state: \.arculusForgotPIN, action: \.arculusForgotPIN) {
				ArculusForgotPIN.InputSeedPhrase()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .renameTapped:
			state.destination = .rename(.init(kind: .factorSource(state.factorSource, name: state.name)))
			return .none

		case .viewSeedPhraseTapped:
			return exportMnemonic(integrity: state.integrity) {
				state.destination = .displayMnemonic(.init(mnemonic: $0.mnemonicWithPassphrase.mnemonic, factorSourceID: $0.factorSourceID))
			}

		case .enterSeedPhraseTapped:
			guard let deviceFS = state.integrity.factorSource.asDevice else {
				return .none
			}
			state.destination = .importMnemonic(.init(deviceFactorSource: deviceFS, profileToCheck: .current))
			return .none

		case .changePinTapped:
			guard let arculusFS = state.integrity.factorSource.asArculus else {
				return .none
			}
			state.destination = .arculusUpdatePIN(.init(factorSource: arculusFS))
			return .none

		case .forgotPinTapped:
			guard let arculusFS = state.integrity.factorSource.asArculus else {
				return .none
			}
			state.destination = .arculusForgotPIN(.init(factorSource: arculusFS))
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .integrityUpdated(factorSourceIntegrity):
			state.integrity = factorSourceIntegrity
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .rename(.delegate(.labelUpdated(.factorSource(_, name)))):
			state.name = name
			state.destination = nil
			return .none

		case .displayMnemonic(.delegate):
			state.destination = nil
			return .none

		case let .importMnemonic(.delegate(.imported(fs))):
			state.destination = nil
			return .run { send in
				let integrity = try await SargonOs.shared.factorSourceIntegrity(factorSource: fs.asGeneral)
				await send(.internal(.integrityUpdated(integrity)))
			} catch: { err, _ in
				errorQueue.schedule(err)
			}

		case .importMnemonic(.delegate(.closed)):
			state.destination = nil
			return .none

		case .arculusUpdatePIN(.delegate(.finished)):
			state.destination = nil
			return .none

		case .arculusForgotPIN(.delegate(.finished)):
			state.destination = nil
			return .none

		default:
			return .none
		}
	}
}

private extension AlertState<Never> {
	static var spotCheckSuccess: AlertState {
		AlertState {
			TextState("")
		} message: {
			TextState(L10n.FactorSources.Detail.spotCheckSuccess)
		}
	}

	static var spotCheckFailure: AlertState {
		AlertState {
			TextState("")
		} message: {
			TextState(L10n.FactorSources.Detail.spotCheckFailure)
		}
	}
}
