import FeaturePrelude

// MARK: - GatewayList
public struct GatewayList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var gateways: IdentifiedArrayOf<GatewayRow.State>

		public init(
			gateways: IdentifiedArrayOf<GatewayRow.State>
		) {
			self.gateways = gateways
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum ChildAction: Sendable, Equatable {
		case gateway(id: GatewayRow.State.ID, action: GatewayRow.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case removeGateway(GatewayRow.State)
		case switchToGateway(Radix.Gateway)
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.gateways, action: /Action.child .. ChildAction.gateway) {
				GatewayRow()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .gateway(id: id, action: .delegate(action)):
			switch action {
			case .didSelect:
				guard let gateway = state.gateways[id: id] else { return .none }
				return .send(.delegate(.switchToGateway(gateway.gateway)))

			case .removeButtonTapped:
				guard let gateway = state.gateways[id: id] else { return .none }
				return .send(.delegate(.removeGateway(gateway)))
			}

		default:
			return .none
		}
	}
}
