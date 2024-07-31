import ComposableArchitecture
import SwiftUI

// MARK: - GatewayRow
@Reducer
public struct GatewayRow: Sendable, FeatureReducer {
	@ObservableState
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = URL
		public var id: URL { gateway.id }

		let gateway: Gateway
		var name: String { gateway.displayName }
		var description: String { gateway.network.displayDescription }
		var isSelected: Bool
		let canBeDeleted: Bool

		public init(
			gateway: Gateway,
			isSelected: Bool,
			canBeDeleted: Bool
		) {
			self.gateway = gateway
			self.isSelected = isSelected
			self.canBeDeleted = canBeDeleted
		}
	}

	public typealias Action = FeatureAction<Self>

	public enum ViewAction: Sendable, Equatable {
		case didSelect
		case removeButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case didSelect
		case removeButtonTapped
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .didSelect:
			.send(.delegate(.didSelect))

		case .removeButtonTapped:
			.send(.delegate(.removeButtonTapped))
		}
	}
}
