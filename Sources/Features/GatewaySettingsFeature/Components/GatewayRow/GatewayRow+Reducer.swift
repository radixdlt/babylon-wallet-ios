import FeaturePrelude

// MARK: - GatewayRow
public struct GatewayRow: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = URL
		public var id: URL { gateway.id }

		let gateway: Radix.Gateway
		var isSelected: Bool
		let canBeDeleted: Bool

		public init(
			gateway: Radix.Gateway,
			isSelected: Bool,
			canBeDeleted: Bool
		) {
			self.gateway = gateway
			self.isSelected = isSelected
			self.canBeDeleted = canBeDeleted
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case didSelect
		case removeButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case didSelect
		case removeButtonTapped
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .didSelect:
			return .send(.delegate(.didSelect))

		case .removeButtonTapped:
			return .send(.delegate(.removeButtonTapped))
		}
	}
}
