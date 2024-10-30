import ComposableArchitecture
import SwiftUI

// MARK: - GatewayRow
@Reducer
struct GatewayRow: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable, Identifiable {
		typealias ID = URL
		var id: URL { gateway.id }

		let gateway: Gateway
		var name: String { gateway.displayName }
		var description: String { gateway.network.displayDescription }
		var isSelected: Bool
		let canBeDeleted: Bool

		init(
			gateway: Gateway,
			isSelected: Bool,
			canBeDeleted: Bool
		) {
			self.gateway = gateway
			self.isSelected = isSelected
			self.canBeDeleted = canBeDeleted
		}
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case didSelect
		case removeButtonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case didSelect
		case removeButtonTapped
	}

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .didSelect:
			.send(.delegate(.didSelect))

		case .removeButtonTapped:
			.send(.delegate(.removeButtonTapped))
		}
	}
}
