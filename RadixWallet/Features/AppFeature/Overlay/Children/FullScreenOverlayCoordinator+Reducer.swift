struct FullScreenOverlayCoordinator: FeatureReducer {
	struct State: Hashable, Identifiable {
		let id: UUID = .init()
		var root: Root.State

		init(root: Root.State) {
			self.root = root
		}
	}

	@CasePathable
	enum ChildAction: Equatable {
		case root(Root.Action)
	}

	enum DelegateAction: Equatable {
		case claimWallet(ClaimWallet.DelegateAction)
		case dismiss
	}

	struct Root: Hashable, Reducer {
		@CasePathable
		enum State: Hashable {
			case claimWallet(ClaimWallet.State)
		}

		@CasePathable
		enum Action: Equatable {
			case claimWallet(ClaimWallet.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.claimWallet, action: \.claimWallet) {
				ClaimWallet()
			}
		}
	}

	init() {}

	var body: some ReducerOf<Self> {
		Scope(state: \.root, action: \.child.root) {
			Root()
		}
		Reduce(core)
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		// Forward all delegate actions, re-wrapped
		case let .root(.claimWallet(.delegate(action))):
			.send(.delegate(.claimWallet(action)))

		default:
			.none
		}
	}
}
