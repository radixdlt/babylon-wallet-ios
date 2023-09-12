import FeaturePrelude
import LoggerDependency

public struct LSUStake: FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public var id: String {
			stake.validator.address.address
		}

		typealias AssetID = AccountPortfolio.NonFungibleResource.NonFungibleToken.ID

		let stake: AccountPortfolio.PoolUnitResources.RadixNetworkStake

		var isStakeSelected: Bool?
		var selectedStakeClaimAssets: OrderedSet<AssetID>?

		@PresentationState
		var destination: Destinations.State?
	}

	public enum ViewAction: Sendable, Equatable {
		case didTap
		case didTapStakeClaimNFT(withID: ViewState.StakeClaimNFTViewState.ID)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public struct Destinations: Sendable, Reducer {
		public enum State: Sendable, Hashable {
			case details(LSUDetails.State)
		}

		public enum Action: Sendable, Equatable {
			case details(LSUDetails.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(
				state: /State.details,
				action: /Action.details,
				child: LSUDetails.init
			)
		}
	}

	@Dependency(\.logger) var logger

	public var body: some ReducerOf<Self> {
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
			if state.isStakeSelected != nil {
				state.isStakeSelected?.toggle()

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
		case let .didTapStakeClaimNFT(withID: id):
			if state.isStakeSelected != nil {
				state.selectedStakeClaimAssets?.toggle(id)
			}

			return .none
		}
	}
}
