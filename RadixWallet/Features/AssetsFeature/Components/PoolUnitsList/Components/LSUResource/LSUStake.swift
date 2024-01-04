import ComposableArchitecture
import SwiftUI

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
		var isExpanded: Bool = false

		@PresentationState
		var destination: Destination.State?
	}

	public enum ViewAction: Sendable, Equatable {
		case expandToggled
		case didTap
		case didTapStakeClaimNFT(withID: ViewState.StakeClaimNFTViewState.ID)
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case details(LSUDetails.State)
			case stakeClaimDetails(NonFungibleTokenDetails.State)
		}

		public enum Action: Sendable, Equatable {
			case details(LSUDetails.Action)
			case stakeClaimDetails(NonFungibleTokenDetails.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(
				state: /State.details,
				action: /Action.details,
				child: LSUDetails.init
			)

			Scope(
				state: /State.stakeClaimDetails,
				action: /Action.stakeClaimDetails,
				child: NonFungibleTokenDetails.init
			)
		}
	}

	@Dependency(\.logger) var logger
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .expandToggled:
			state.isExpanded.toggle()
			return .none
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
			guard let nftResource = stakeDetails.stakeClaimTokens,
			      let token = nftResource.tokens.first(where: { $0.id == id })
			else {
				assertionFailure("Did tapp a missing NFT?")
				return .none
			}

			if state.selectedStakeClaimAssets != nil {
				state.selectedStakeClaimAssets?.toggle(token)
			}

			state.destination = .stakeClaimDetails(.init(
				resourceAddress: nftResource.resource.resourceAddress,
				resourceDetails: .success(nftResource.resource),
				token: token,
				ledgerState: nftResource.resource.atLedgerState
			))
			return .none
		}
	}
}

extension OnLedgerEntitiesClient.OwnedStakeDetails {
	var xrdRedemptionValue: RETDecimal {
		((stakeUnitResource?.amount ?? 0) * validator.xrdVaultBalance) / (stakeUnitResource?.resource.totalSupply ?? 1)
	}
}
