// MARK: - ChooseFactorSourceCoordinator
@Reducer
struct ChooseFactorSourceCoordinator: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var chooseKind: ChooseFactorSourceKind.State = .init()
		var path: StackState<Path.State> = .init()
	}

	@Reducer(state: .hashable, action: .equatable)
	enum Path {
		case chooseFactorSource(FactorSourcesList)
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case appeared
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case chooseKind(ChooseFactorSourceKind.Action)
		case path(StackActionOf<Path>)
	}

	enum DelegateAction: Sendable, Equatable {
		case finished(FactorSource)
	}

	var body: some ReducerOf<Self> {
		Scope(state: \.chooseKind, action: \.child.chooseKind) {
			ChooseFactorSourceKind()
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
		case let .chooseKind(.delegate(.chosenKind(kind))):
			state.path.append(.chooseFactorSource(.init(kind: kind)))
			return .none
		default:
			return .none
		}
	}
}
