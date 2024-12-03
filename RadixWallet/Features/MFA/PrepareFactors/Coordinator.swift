
extension PrepareFactors {
	@Reducer
	struct Coordinator: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			var root: PrepareFactors.Intro.State = .init()
			var path: StackState<Path.State> = .init()
		}

		@Reducer(state: .hashable, action: .equatable)
		enum Path {
			case addHardwareFactor(PrepareFactors.AddHardwareFactor)
			case addAnotherFactor(PrepareFactors.AddAnotherFactor)
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case appeared
		}

		@CasePathable
		enum ChildAction: Sendable, Equatable {
			case root(PrepareFactors.Intro.Action)
			case path(StackAction<Path.State, Path.Action>)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.root, action: \.child.root) {
				PrepareFactors.Intro()
			}
			Reduce(core)
				.forEach(\.path, action: \.child.path)
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .appeared:
				.none
			}
		}

		func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
			switch childAction {
			case .root(.delegate(.start)):
				state.path.append(.addHardwareFactor(.init()))
				return .none
			case .path(.element(id: _, action: .addHardwareFactor(.delegate(.addedFactorSource)))):
				state.path.append(.addAnotherFactor(.init()))
				return .none
			default:
				return .none
			}
		}
	}
}
