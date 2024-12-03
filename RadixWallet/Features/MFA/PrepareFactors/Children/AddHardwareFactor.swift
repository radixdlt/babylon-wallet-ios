extension PrepareFactors {
	@Reducer
	struct AddHardwareFactor: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			var selected: FactorSourceKind?

			@Presents
			var destination: Destination.State?
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case selected(FactorSourceKind)
			case addButtonTapped
			case noDeviceButtonTapped
		}

		enum DelegateAction: Sendable, Equatable {
			case addedFactorSource
		}

		struct Destination: DestinationReducer {
			@CasePathable
			enum State: Sendable, Hashable {
				case addLedger(AddLedgerFactorSource.State)
				case noDeviceAlert(AlertState<Never>)
			}

			@CasePathable
			enum Action: Sendable, Equatable {
				case addLedger(AddLedgerFactorSource.Action)
				case noDeviceAlert(Never)
			}

			var body: some ReducerOf<Self> {
				Scope(state: \.addLedger, action: \.addLedger) {
					AddLedgerFactorSource()
				}
			}
		}

		var body: some ReducerOf<Self> {
			Reduce(core)
				.ifLet(\.$destination, action: \.destination) {
					Destination()
				}
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case let .selected(value):
				state.selected = value
				return .none
			case .addButtonTapped:
				switch state.selected {
				case .ledgerHqHardwareWallet:
					state.destination = .addLedger(.init())
				case .arculusCard:
					loggerGlobal.info("Arculus card flow not yet implemented")
					return .send(.delegate(.addedFactorSource)) // TODO: Remove
				default:
					loggerGlobal.error("Unexpected tap on add button with state \(String(describing: state.selected))")
				}
				return .none
			case .noDeviceButtonTapped:
				state.destination = .noDeviceAlert(.init(
					title: { TextState("Show something") },
					actions: {
						.default(TextState(L10n.Common.ok))
					}
				))
				return .none
			}
		}

		func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
			switch presentedAction {
			case let .addLedger(.delegate(action)):
				switch action {
				case .completed:
					state.destination = nil
					return .send(.delegate(.addedFactorSource))
				case .failedToAddLedger, .dismiss:
					state.destination = nil
					return .none
				}

			default:
				return .none
			}
		}
	}
}
