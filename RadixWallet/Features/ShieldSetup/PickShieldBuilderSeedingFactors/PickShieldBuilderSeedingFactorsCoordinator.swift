import ComposableArchitecture

// MARK: - PickShieldBuilderSeedingFactorsCoordinator.Path.State + Hashable
extension PickShieldBuilderSeedingFactorsCoordinator.Path.State: Hashable {}

// MARK: - PickShieldBuilderSeedingFactorsCoordinator.Path.Action + Equatable
extension PickShieldBuilderSeedingFactorsCoordinator.Path.Action: Equatable {}

// MARK: - PickShieldBuilderSeedingFactorsCoordinator
@Reducer
struct PickShieldBuilderSeedingFactorsCoordinator: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var path: Path.State
	}

	@Reducer
	enum Path {
		case pickShieldBuilderSeedingFactors(PickShieldBuilderSeedingFactors)
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case path(Path.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case finished
		case push(Path.State)
	}

	var body: some ReducerOf<Self> {
		Scope(state: \.path, action: \.child.path) {
			Path.pickShieldBuilderSeedingFactors(PickShieldBuilderSeedingFactors())
		}
		Reduce(core)
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .path(.pickShieldBuilderSeedingFactors(.delegate(.finished))):
			.send(.delegate(.finished))
		default:
			.none
		}
	}
}
