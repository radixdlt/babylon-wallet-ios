// MARK: - ArculusFactorSourceAccess
@Reducer
struct ArculusFactorSourceAccess: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let factorSource: ArculusCardFactorSource
		var pinInput: ArculusPINInput.State = .init(shouldConfirmPIN: false)

		@Presents
		var destination: Destination.State?
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Hashable {
		case pinAdded(String)
		case forgotPinButtonTapped
	}

	@CasePathable
	enum ChildAction: Sendable, Hashable {
		case pinInput(ArculusPINInput.Action)
	}

	enum DelegateAction: Sendable, Hashable {
		case perform(PrivateFactorSource)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case arculusForgotPIN(ArculusForgotPIN.InputSeedPhrase.State)
		}

		@CasePathable
		enum Action: Sendable, Hashable {
			case arculusForgotPIN(ArculusForgotPIN.InputSeedPhrase.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.arculusForgotPIN, action: \.arculusForgotPIN) {
				ArculusForgotPIN.InputSeedPhrase()
			}
		}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	var body: some ReducerOf<Self> {
		Scope(state: \.pinInput, action: \.child.pinInput) {
			ArculusPINInput()
		}
		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .pinAdded(pin):
			return .send(.delegate(.perform(.arculusCard(state.factorSource, pin))))
		case .forgotPinButtonTapped:
			state.destination = .arculusForgotPIN(.init(factorSource: state.factorSource))
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .arculusForgotPIN(.delegate(.finished)):
			state.destination = nil
			return .none
		default:
			return .none
		}
	}
}
