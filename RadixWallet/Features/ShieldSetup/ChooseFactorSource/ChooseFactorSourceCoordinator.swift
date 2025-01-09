// MARK: - ChooseFactorSourceCoordinator
@Reducer
struct ChooseFactorSourceCoordinator: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let role: RoleKind
		var kind: ChooseFactorSourceKind.State = .init()
		var path: StackState<Path.State> = .init()
	}

	@Reducer(state: .hashable, action: .equatable)
	enum Path {
		case list(FactorSourcesList)
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case appeared
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case kind(ChooseFactorSourceKind.Action)
		case path(StackActionOf<Path>)
	}

	enum DelegateAction: Sendable, Equatable {
		case finished(FactorSource)
	}

	var body: some ReducerOf<Self> {
		Scope(state: \.kind, action: \.child.kind) {
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
		case let .kind(.delegate(.chosenKind(kind))):
			state.path.append(.list(.init(context: .selection, kind: kind)))
			return .none
		case let .path(.element(id: _, action: .list(.delegate(.selectedFactorSource(factorSource))))):
			return .send(.delegate(.finished(factorSource)))
		default:
			return .none
		}
	}
}
