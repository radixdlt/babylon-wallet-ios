// MARK: - PrepareFactors.Coordinator
extension PrepareFactors {
	@Reducer
	struct Coordinator: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			var path: PrepareFactors.Path.State

			@Presents
			var destination: Destination.State?
		}

		typealias Action = FeatureAction<Self>

		@CasePathable
		enum ChildAction: Sendable, Equatable {
			case path(PrepareFactors.Path.Action)
		}

		enum DelegateAction: Sendable, Equatable {
			case finished
			case push(PrepareFactors.Path.State)
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
			Scope(state: \.path, action: \.child.path) {
				PrepareFactors.Path()
			}
			Reduce(core)
				.ifLet(destinationPath, action: \.destination) {
					Destination()
				}
		}

		private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

		func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
			switch childAction {
			case .path(.introFinished):
				determineNextStepEffect()
			case let .path(.addFactor(.delegate(.addFactorSource(kind)))):
				addFactorSourceEffect(&state, kind: kind)
			case .path(.completionFinished):
				.send(.delegate(.finished))
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
			let status = try await factorSourcesClient.getShieldFactorStatus()
			switch status {
			case .hardwareRequired:
				await send(.delegate(.push(.addFactor(.init(mode: .hardware)))))
			case .anyRequired:
				await send(.delegate(.push(.addFactor(.init(mode: .any)))))
			case .valid:
				await send(.delegate(.push(.completion)))
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
