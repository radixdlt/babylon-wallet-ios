import ComposableArchitecture
import SwiftUI

// MARK: - GatewayRow.State + Comparable
extension GatewayRow.State: Comparable {
	static func < (lhs: Self, rhs: Self) -> Bool {
		if lhs.canBeDeleted, !rhs.canBeDeleted {
			return false
		}

		return lhs.gateway.network.id < rhs.gateway.network.id &&
			lhs.gateway.displayName < rhs.gateway.displayName
	}
}

// MARK: - GatewayList
@Reducer
struct GatewayList: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var gateways: IdentifiedArrayOf<GatewayRow.State>

		init(
			gateways: IdentifiedArrayOf<GatewayRow.State>
		) {
			self.gateways = gateways
		}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case appeared
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case gateway(id: GatewayRow.State.ID, action: GatewayRow.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case removeGateway(GatewayRow.State)
		case switchToGateway(Gateway)
	}

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.gateways, action: /Action.child .. ChildAction.gateway) {
				GatewayRow()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			.none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
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
