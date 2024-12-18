// MARK: - DeviceFactorSourceDetail

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
		case changePinTapped
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case rename(RenameLabel.State)
			case displayMnemonic(DisplayMnemonic.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case rename(RenameLabel.Action)
			case displayMnemonic(DisplayMnemonic.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.rename, action: \.rename) {
				RenameLabel()
			}
			Scope(state: \.displayMnemonic, action: \.displayMnemonic) {
				DisplayMnemonic()
			}
		}
	}

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
		case .changePinTapped:
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

		default:
			return .none
		}
	}
}
