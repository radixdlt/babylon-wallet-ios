// MARK: - ArculusChangePIN
// Namespace
enum ArculusChangePIN {}

// MARK: ArculusChangePIN.EnterOldPIN
extension ArculusChangePIN {
	@Reducer
	struct EnterOldPIN: FeatureReducer {
		@ObservableState
		struct State: Hashable {
			let factorSource: ArculusCardFactorSource

			var pinInput: ArculusPINInput.State = .init(shouldConfirmPIN: false)

			@Presents
			var destination: Destination.State?
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Equatable {
			case pinAdded(String)
		}

		enum DelegateAction: Equatable {
			case finished
		}

		enum InternalAction: Equatable {
			case pinVerified
		}

		@CasePathable
		enum ChildAction: Equatable {
			case pinInput(ArculusPINInput.Action)
		}

		struct Destination: DestinationReducer {
			@CasePathable
			enum State: Hashable {
				case configureNewPIN(ArculusChangePIN.EnterNewPIN.State)
			}

			@CasePathable
			enum Action: Equatable {
				case configureNewPIN(ArculusChangePIN.EnterNewPIN.Action)
			}

			var body: some ReducerOf<Self> {
				Scope(state: \.configureNewPIN, action: \.configureNewPIN) {
					ArculusChangePIN.EnterNewPIN()
				}
			}
		}

		@Dependency(\.errorQueue) var errorQueue
		@Dependency(\.arculusCardClient) var arculusCardClient
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
				.run { [fs = state.factorSource] send in
					try await arculusCardClient.verifyPin(fs, pin)
					await send(.internal(.pinVerified))
				} catch: { _, _ in }
			}
		}

		func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
			switch internalAction {
			case .pinVerified:
				state.destination = .configureNewPIN(.init(factorSource: state.factorSource, oldPIN: state.pinInput.validatedPin!))
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
