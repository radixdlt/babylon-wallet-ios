import FeaturePrelude
import LoggerDependency

// MARK: - LSUStake
public struct LSUStake: FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public var id: String {
			stake.validator.address.address
		}

		typealias AssetID = OnLedgerEntity.NonFungibleToken.ID

		let stake: AccountPortfolio.PoolUnitResources.RadixNetworkStake

		var isStakeSelected: Bool?
		var selectedStakeClaimAssets: OrderedSet<OnLedgerEntity.NonFungibleToken>?

		var stakeResource: OnLedgerEntity.Resource?
		var stakeClaimNFTResource: OnLedgerEntity.Resource?
		var stakeClaimNfts: [OnLedgerEntity.NonFungibleToken] = []

		@PresentationState
		var destination: Destinations.State?
	}

	public enum ViewAction: Sendable, Equatable {
		case didTap
		case didTapStakeClaimNFT(withID: ViewState.StakeClaimNFTViewState.ID)
		case task
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
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

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
	) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .none

		case .didTap:
			if state.isStakeSelected != nil {
				state.isStakeSelected?.toggle()

				return .none
			} else {
				guard
					let stakeAmount = state.stake.stakeUnitResource?.amount,
					let resource = state.stakeResource
				else {
					logger.fault("We should not be able to tap a stake in such state")

					return .none
				}

				state.destination = .details(
					.init(
						validator: state.stake.validator,
						stakeUnitResource: resource,
						stakeAmount: stakeAmount,
						xrdRedemptionValue: state.xrdRedemptionValue
					)
				)

				return .none
			}
		case let .didTapStakeClaimNFT(withID: id):
			guard let token = state.stakeClaimNfts.first(where: { $0.id == id }) else {
				assertionFailure("Did tapp a missing NFT?")
				return .none
			}
			if state.isStakeSelected != nil {
				state.selectedStakeClaimAssets?.toggle(token)
			}

			// TODO: Show details
			return .none
		}
	}
}

import EngineKit
extension LSUStake.State {
	var xrdRedemptionValue: RETDecimal {
		((stake.stakeUnitResource?.amount ?? 0) * stake.validator.xrdVaultBalance) / (stakeResource?.totalSupply ?? 1)
	}
}
