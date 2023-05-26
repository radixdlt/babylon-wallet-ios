import FeaturePrelude
import Profile

// MARK: - DebugInspectProfile
public struct DebugInspectProfile: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let profile: Profile
		public init(profile: Profile) {
			self.profile = profile
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}
}
