// MARK: - FactorSourceDetail
struct FactorSourceDetail: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let integrity: FactorSourceIntegrity
		var name: String

		init(integrity: FactorSourceIntegrity) {
			self.integrity = integrity
			self.name = integrity.factorSource.asGeneral.name
		}

		@PresentationState
		var destination: Destination.State?

		var factorSource: FactorSource {
			integrity.factorSource
		}
	}

	enum ViewAction: Sendable, Equatable {
		case renameTapped
		case viewSeedPhraseTapped
		case enterSeedPhraseTapped
		case changePinTapped
		case spotCheckTapped
	}

	enum InternalAction: Sendable, Hashable {
		case spotCheckResult(Bool)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case rename(RenameLabel.State)
			case displayMnemonic(DisplayMnemonic.State)
			case importMnemonics(ImportMnemonicsFlowCoordinator.State)
			case spotCheckAlert(AlertState<Never>)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case rename(RenameLabel.Action)
			case displayMnemonic(DisplayMnemonic.Action)
			case importMnemonics(ImportMnemonicsFlowCoordinator.Action)
			case spotCheckAlert(Never)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.rename, action: \.rename) {
				RenameLabel()
			}
			Scope(state: \.displayMnemonic, action: \.displayMnemonic) {
				DisplayMnemonic()
			}
			Scope(state: \.importMnemonics, action: \.importMnemonics) {
				ImportMnemonicsFlowCoordinator()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
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
				state.destination = .displayMnemonic(.export($0, title: L10n.RevealSeedPhrase.title, context: .fromSettings))
			}

		case .enterSeedPhraseTapped:
			state.destination = .importMnemonics(.init())
			return .none

		case .changePinTapped:
			return .none

		case .spotCheckTapped:
			return .run { [factorSource = state.factorSource] send in
				let result = try await SargonOS.shared.triggerSpotCheck(factorSource: factorSource)
				await send(.internal(.spotCheckResult(result)))
			} catch: { error, send in
				if error.isHostInteractionAborted {
					// Tapping on Close button is considered a failure
					await send(.internal(.spotCheckResult(false)))
				} else {
					errorQueue.schedule(error)
				}
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .spotCheckResult(success):
			state.destination = .spotCheckAlert(success ? .spotCheckSuccess : .spotCheckFailure)
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .rename(.delegate(.labelUpdated(.factorSource(_, name)))):
			state.name = name
			state.destination = nil
			return .none

		case .displayMnemonic(.delegate), .importMnemonics(.delegate):
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
