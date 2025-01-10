// MARK: - ChooseFactorSourceCoordinator
@Reducer
struct ChooseFactorSourceCoordinator: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		@Shared(.shieldBuilder) var shieldBuilder
		let context: ChooseFactorSourceContext
		var kind: ChooseFactorSourceKind.State
		var path: StackState<Path.State>

		init(context: ChooseFactorSourceContext) {
			self.context = context
			self.kind = .init(context: context)
			self.path = .init()
		}
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
		case finished
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
			state.path.append(.list(.init(context: .selection(state.context), kind: kind)))
			return .none
		case let .path(.element(id: _, action: .list(.delegate(.selectedFactorSource(factorSource))))):
			return selectedFactorSourceEffect(state: state, factorSourceId: factorSource.id)
		default:
			return .none
		}
	}
}

private extension ChooseFactorSourceCoordinator {
	func selectedFactorSourceEffect(state: State, factorSourceId: FactorSourceID) -> Effect<Action> {
		state.$shieldBuilder.withLock { builder in
			switch state.context {
			case .primaryThreshold:
				builder = builder.addFactorSourceToPrimaryThreshold(factorSourceId: factorSourceId)
			case .primaryOverride:
				builder = builder.addFactorSourceToPrimaryOverride(factorSourceId: factorSourceId)
			case .recovery:
				builder = builder.addFactorSourceToRecoveryOverride(factorSourceId: factorSourceId)
			case .confirmation:
				builder = builder.addFactorSourceToConfirmationOverride(factorSourceId: factorSourceId)
			}
		}
		return .send(.delegate(.finished))
	}
}

// MARK: - ChooseFactorSourceContext
// TODO: Remove String & CaseIterable added for tests
enum ChooseFactorSourceContext: String, Sendable, Hashable, CaseIterable {
	case primaryThreshold
	case primaryOverride
	case recovery
	case confirmation
}
