
extension PrepareFactors {
	@Reducer
	struct Coordinator: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			var root: PrepareFactors.Intro.State = .init()
			var path: StackState<Path.State> = .init()
		}

		// TOOD: Check using enum with @Reducer(state: .equatable)
		struct Path: Sendable, Reducer {
			@CasePathable
			@ObservableState
			enum State: Sendable, Hashable {
				case addHardwareFactor(PrepareFactors.AddHardwareFactor.State)
			}

			@CasePathable
			enum Action: Sendable, Equatable {
				case addHardwareFactor(PrepareFactors.AddHardwareFactor.Action)
			}

			var body: some ReducerOf<Self> {
				Scope(state: \.addHardwareFactor, action: \.addHardwareFactor) {
					PrepareFactors.AddHardwareFactor()
				}
			}
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case appeared
		}

		@CasePathable
		enum ChildAction: Sendable, Equatable {
			case root(PrepareFactors.Intro.Action)
			case path(StackActionOf<Path>)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.root, action: \.child.root) {
				PrepareFactors.Intro()
			}
			Reduce(core)
				.forEach(\.path, action: \.child.path) {
					Path()
				}
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .appeared:
				.none
			}
		}

		func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
			switch childAction {
			case let .root(.delegate(action)):
				switch action {
				case .start:
					state.path.append(.addHardwareFactor(.init()))
				case .dismiss:
					break
				}
				return .none
			default:
				return .none
			}
		}
	}
}
