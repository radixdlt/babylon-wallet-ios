import FeaturePrelude

// MARK: - PoolUnitDetails
public struct PoolUnitDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}
}
