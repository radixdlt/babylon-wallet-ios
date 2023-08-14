import FeaturePrelude
import LoggerDependency

public struct LSUStake: FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public var id: String {
			stake.validator.address.address
		}

		let stake: AccountPortfolio.PoolUnitResources.RadixNetworkStake

		var isSelected: Bool?

		@PresentationState
		public var destination: Destinations.State?
	}

	public enum ViewAction: Sendable, Equatable {
		case didTap
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case details(LSUDetails.State)
		}

		public enum Action: Sendable, Equatable {
			case details(LSUDetails.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(
				state: /State.details,
				action: /Action.details,
				child: LSUDetails.init
			)
		}
	}

	@Dependency(\.logger) var logger

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(
				\.$destination,
				action: /Action.child .. ChildAction.destination,
				destination: Destinations.init
			)
	}

	public func reduce(
		into state: inout State,
		viewAction: ViewAction
	) -> EffectTask<Action> {
		switch viewAction {
		case .didTap:
			if state.isSelected != nil {
				state.isSelected?.toggle()

				return .none
			} else {
				guard
					let resource = state.stake.stakeUnitResource,
					let xrdRedemptionValue = state.stake.xrdRedemptionValue
				else {
					logger.fault("We should not be able to tap a stake in such state")

					return .none
				}

				state.destination = .details(
					.init(
						validator: state.stake.validator,
						stakeUnitResource: resource,
						xrdRedemptionValue: xrdRedemptionValue
					)
				)

				return .none
			}
		}
	}
}
