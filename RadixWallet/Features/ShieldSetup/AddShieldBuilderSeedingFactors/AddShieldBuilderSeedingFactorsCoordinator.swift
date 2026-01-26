// MARK: - AddShieldBuilderSeedingFactors.Coordinator
extension AddShieldBuilderSeedingFactors {
	@Reducer
	struct Coordinator: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			var path: Path.State

			@Presents
			var destination: Destination.State?
		}

		@Reducer
		enum Path {
			case intro
			case addFactor(AddShieldBuilderSeedingFactors.SelectFactorSourceToAdd)
			case completion
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case introButtonTapped
			case completionButtonTapped
		}

		@CasePathable
		enum ChildAction: Sendable, Equatable {
			case path(Path.Action)
		}

		enum DelegateAction: Sendable, Equatable {
			case finished(shouldSkipAutomaticShield: Bool)
			case push(Path.State)
		}

		struct Destination: DestinationReducer {
			@CasePathable
			enum State: Sendable, Hashable {
				case addFactorSource(AddFactorSource.Coordinator.State)
				case todo
			}

			@CasePathable
			enum Action: Sendable, Equatable {
				case addFactorSource(AddFactorSource.Coordinator.Action)
				case todo(Never)
			}

			var body: some ReducerOf<Self> {
				Scope(state: \.addFactorSource, action: \.addFactorSource) {
					AddFactorSource.Coordinator()
				}
			}
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.path, action: \.child.path) {
				Path.intro
			}
			Reduce(core)
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
				.send(.delegate(.finished(shouldSkipAutomaticShield: false)))
			}
		}

		func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
			switch childAction {
			case let .path(.addFactor(.delegate(.addFactorSource(kind)))):
				addFactorSourceEffect(&state, kind: kind)
			case .path(.addFactor(.delegate(.skipAutomaticShield))):
				.send(.delegate(.finished(shouldSkipAutomaticShield: true)))
			default:
				.none
			}
		}

		func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
			switch presentedAction {
			case let .addFactorSource(.delegate(.finished)):
				state.destination = nil
				return determineNextStepEffect()
			default:
				return .none
			}
		}
	}
}

// MARK: - AddShieldBuilderSeedingFactors.Coordinator.Path.State + Hashable
extension AddShieldBuilderSeedingFactors.Coordinator.Path.State: Hashable {}

// MARK: - AddShieldBuilderSeedingFactors.Coordinator.Path.Action + Equatable
extension AddShieldBuilderSeedingFactors.Coordinator.Path.Action: Equatable {}

private extension AddShieldBuilderSeedingFactors.Coordinator {
	func determineNextStepEffect() -> Effect<Action> {
		.run { send in
			let status = try SargonOS.shared.securityShieldPrerequisitesStatus()
			switch status {
			case .hardwareRequired:
				await send(.delegate(.push(.addFactor(.init(mode: .hardware)))))
			case .anyRequired:
				await send(.delegate(.push(.addFactor(.init(mode: .any)))))
			case .sufficient:
				await send(.delegate(.push(.completion)))
			}
		}
	}

	func addFactorSourceEffect(_ state: inout State, kind: FactorSourceKind) -> Effect<Action> {
		state.destination = .addFactorSource(.init(mode: .preselectedKind(kind), context: .newFactorSource))
		return .none
	}
}
