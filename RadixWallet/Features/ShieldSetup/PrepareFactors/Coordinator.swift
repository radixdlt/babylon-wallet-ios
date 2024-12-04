// MARK: - PrepareFactors.Coordinator
extension PrepareFactors {
	@Reducer
	struct Coordinator: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			var path: StackState<Path.State> = .init()

			@Presents
			var destination: Destination.State?
		}

		@Reducer(state: .hashable, action: .equatable)
		enum Path {
			case addFactor(PrepareFactors.AddFactor)
			case completion
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case introButtonTapped
			case completionButtonTapped
		}

		enum InternalAction: Sendable, Equatable {
			case addHardwareFactor
			case addAnyFactor
			case showCompletion
		}

		@CasePathable
		enum ChildAction: Sendable, Equatable {
			case path(StackActionOf<Path>)
		}

		struct Destination: DestinationReducer {
			@CasePathable
			enum State: Sendable, Hashable {
				case addLedger(AddLedgerFactorSource.State)
			}

			@CasePathable
			enum Action: Sendable, Equatable {
				case addLedger(AddLedgerFactorSource.Action)
			}

			var body: some ReducerOf<Self> {
				Scope(state: \.addLedger, action: \.addLedger) {
					AddLedgerFactorSource()
				}
			}
		}

		@Dependency(\.factorSourcesClient) var factorSourcesClient

		var body: some ReducerOf<Self> {
			Reduce(core)
				.forEach(\.path, action: \.child.path)
				.ifLet(destinationPath, action: \.destination) {
					Destination()
				}
		}

		private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .introButtonTapped:
				determineNextStepEffect()
			case .completionButtonTapped:
				// Inform via delegate that we are done
				.none
			}
		}

		func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
			switch internalAction {
			case .addHardwareFactor:
				state.path.append(.addFactor(.init(mode: .hardwareOnly)))
				return .none
			case .addAnyFactor:
				state.path.append(.addFactor(.init(mode: .any)))
				return .none
			case .showCompletion:
				state.path.append(.completion)
				return .none
			}
		}

		func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
			switch childAction {
			case let .path(.element(id: _, action: .addFactor(.delegate(.addFactorSource(kind))))):
				addFactorSourceEffect(&state, kind: kind)
			default:
				.none
			}
		}

		func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
			switch presentedAction {
			case let .addLedger(.delegate(action)):
				switch action {
				case .completed:
					state.destination = nil
					return determineNextStepEffect()
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

private extension PrepareFactors.Coordinator {
	func determineNextStepEffect() -> Effect<Action> {
		.run { send in
			let status = try await factorSourcesClient.getShieldBuilderStatus()
			switch status {
			case .hardwareRequired:
				await send(.internal(.addHardwareFactor))
			case .anyRequired:
				await send(.internal(.addAnyFactor))
			case .valid:
				await send(.internal(.showCompletion))
			}
		}
	}

	func addFactorSourceEffect(_ state: inout State, kind: FactorSourceKind) -> Effect<Action> {
		switch kind {
		case .ledgerHqHardwareWallet:
			state.destination = .addLedger(.init())
			return .none
		case .arculusCard, .password, .offDeviceMnemonic:
			loggerGlobal.info("Factor Source not implemented yet")
			return .none
		case .securityQuestions, .trustedContact, .device:
			fatalError("Factor Source not supported")
		}
	}
}
