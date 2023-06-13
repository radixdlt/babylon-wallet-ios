import FeaturePrelude

// MARK: - AdvancedCreateSecurityStructureFlow
public struct AdvancedCreateSecurityStructureFlow: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Mode: Sendable, Hashable {
			case existing(SecurityStructureConfiguration)
			case new(New)

			public struct New: Sendable, Hashable {}
		}

		public var mode: Mode

		public init(mode: Mode) {
			self.mode = mode
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
