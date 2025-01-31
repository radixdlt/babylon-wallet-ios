extension ApplyShield {
	@Reducer
	struct Coordinator: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			let shieldID: SecurityStructureId

			var root: Path.State
			var path: StackState<Path.State> = .init()

			init(
				shieldID: SecurityStructureId,
				root: Path.State? = nil
			) {
				self.shieldID = shieldID
				self.root = root ?? .intro(.init(shieldID: shieldID))
			}
		}

		@Reducer(state: .hashable, action: .equatable)
		enum Path {
			case intro(Intro)
			case chooseAccounts(ChooseAccountsForShield)
		}

		typealias Action = FeatureAction<Self>

		@CasePathable
		enum ChildAction: Sendable, Equatable {
			case root(Path.Action)
			case path(StackActionOf<Path>)
		}

		enum DelegateAction: Sendable, Equatable {
			case skipped
			case finished
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.root, action: \.child.root) {
				Path.intro(.init())
			}
			Reduce(core)
				.forEach(\.path, action: \.child.path)
		}

		func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
			switch childAction {
			case .root(.intro(.delegate(.started))):
				state.path.append(.chooseAccounts(.init(
					chooseAccounts: .init(
						context: .permission(.atLeast(1)),
						canCreateNewAccount: false,
						showSelectAllAccounts: true
					)
				)))
				return .none
			case .root(.intro(.delegate(.skipped))):
				return .send(.delegate(.skipped))
			default:
				return .none
			}
		}
	}
}
