import FeaturePrelude
import LoggerDependency
import OnLedgerEntitiesClient

// MARK: - LSUStake
public struct LSUStake: FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public var id: String {
			stake.validatorAddress.address
		}

		typealias AssetID = OnLedgerEntity.NonFungibleToken.ID

		let stake: OnLedgerEntity.Account.RadixNetworkStake
		var stakeDetails: Loadable<OnLedgerEntitiesClient.OwnedStakeDetails>

		var isStakeSelected: Bool?
		var selectedStakeClaimAssets: OrderedSet<OnLedgerEntity.NonFungibleToken>?

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
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(
				\.$destination,
				action: /Action.child .. ChildAction.destination,
				destination: Destinations.init
			)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .didTap:
			guard case let .success(stakeDetails) = state.stakeDetails else {
				return .none
			}

			if state.isStakeSelected != nil {
				state.isStakeSelected?.toggle()
				return .none
			} else {
				guard
					let stakeUnitResource = stakeDetails.stakeUnitResource
				else {
					logger.fault("We should not be able to tap a stake in such state")
					return .none
				}

				state.destination = .details(
					.init(
						validator: stakeDetails.validator,
						stakeUnitResource: stakeUnitResource,
						xrdRedemptionValue: stakeDetails.xrdRedemptionValue
					)
				)

				return .none
			}
		case let .didTapStakeClaimNFT(withID: id):
			guard case let .success(stakeDetails) = state.stakeDetails else {
				return .none
			}
			guard let token = stakeDetails.stakeClaimTokens?.tokens.first(where: { $0.id == id }) else {
				assertionFailure("Did tapp a missing NFT?")
				return .none
			}

			if state.selectedStakeClaimAssets != nil {
				state.selectedStakeClaimAssets?.toggle(token)
			}

			// TODO: Show details
			return .none
		}
	}
}

import EngineKit
extension OnLedgerEntitiesClient.OwnedStakeDetails {
	var xrdRedemptionValue: RETDecimal {
		((stakeUnitResource?.amount ?? 0) * validator.xrdVaultBalance) / (stakeUnitResource?.resource.totalSupply ?? 1)
	}
}
