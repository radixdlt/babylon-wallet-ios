// MARK: - AccountRecoveryScanCoordinator

public struct AccountRecoveryScanCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let context: Context
		public var root: AccountRecoveryScanStart.State
		public var path: StackState<Path.State> = .init()

		public enum Context: Sendable, Hashable {
			/// From onboarding
			case restoreWalletWithOnlyBDFS(PrivateHDFactorSource)

			/// From settings
			case scanForMoreAccounts(FactorSourceID) // will need to load FactorSource from `factorSourcesClient`
		}

		public init(context: Context) {
			self.context = context
			self.root = .init()
		}
	}

	public struct Path: Sendable, Hashable, Reducer {
		public enum State: Sendable, Hashable {
			case end(AccountRecoveryScanEnd.State)
		}

		public enum Action: Sendable, Equatable {
			case end(AccountRecoveryScanEnd.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.end, action: /Action.end) {
				AccountRecoveryScanEnd()
			}
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case root(AccountRecoveryScanStart.Action)
		case path(StackActionOf<Path>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case finishedAccountRecoveryScan(
			active: OrderedSet<Profile.Network.Account>,
			inactive: OrderedSet<Profile.Network.Account>
		)
	}

	@Dependency(\.dismiss) var dismiss
	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.root, action: /Action.child .. ChildAction.root) {
			AccountRecoveryScanStart()
		}

		Reduce(core)
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .root(.delegate(.continue)):
			state.path.append(.end(.init()))
			return .none

		case let .path(.element(_, action: .end(.delegate(.finishedAccountRecoveryScan(active, inactive))))):
			return .send(.delegate(.finishedAccountRecoveryScan(active: active, inactive: inactive)))

		default: return .none
		}
	}
}
