struct FullScreenOverlayCoordinator: Sendable, FeatureReducer {
	struct State: Sendable, Hashable, Identifiable {
		let id: UUID = .init()
		var root: Root.State

		init(root: Root.State) {
			self.root = root
		}
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case root(Root.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case claimWallet(ClaimWallet.DelegateAction)
		case dismiss
	}

	struct Root: Sendable, Hashable, Reducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case claimWallet(ClaimWallet.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
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
