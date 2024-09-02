public struct FullScreenOverlayCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public let id: UUID = .init()
		public var root: Root.State

		public init(root: Root.State) {
			self.root = root
		}
	}

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case root(Root.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case claimWallet(ClaimWallet.DelegateAction)
		case dismiss
	}

	public struct Root: Sendable, Hashable, Reducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case claimWallet(ClaimWallet.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case claimWallet(ClaimWallet.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: \.claimWallet, action: \.claimWallet) {
				ClaimWallet()
			}
		}
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.root, action: \.child.root) {
			Root()
		}
		Reduce(core)
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		// Forward all delegate actions, re-wrapped
		case let .root(.claimWallet(.delegate(action))):
			.send(.delegate(.claimWallet(action)))

		default:
			.none
		}
	}
}
