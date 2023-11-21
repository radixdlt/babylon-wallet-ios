// MARK: - AccountRecoveryScanEnd

public struct AccountRecoveryScanEnd: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case doneTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case finishedAccountRecoveryScan(
			active: OrderedSet<Profile.Network.Account>,
			inactive: OrderedSet<Profile.Network.Account>
		)
	}

	public init() {}

	public func reduce(into _: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .doneTapped:
			.send(.delegate(.finishedAccountRecoveryScan(active: [], inactive: [])))
		}
	}
}
