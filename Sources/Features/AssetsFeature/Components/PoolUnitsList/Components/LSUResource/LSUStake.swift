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

		var stakeResource: Loadable<OnLedgerEntity.Resource> = .idle
		var stakeClaimNfts: Loadable<[OnLedgerEntity.NonFungibleToken]> = .idle

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

	public enum InternalAction: Sendable, Equatable {
		case stakeUnitResourceLoaded(TaskResult<OnLedgerEntity.Resource>)
		case stakeClaimNftsLoaded(TaskResult<[OnLedgerEntity.NonFungibleToken]>)
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
			guard case .idle = state.stakeResource, let stakeUnitAddress = state.stake.stakeUnitResource?.resourceAddress else {
				return .none
			}
			state.stakeResource = .loading

			return .run { send in
				try await Task.sleep(for: .seconds(2))
				let result = await TaskResult { try await onLedgerEntitiesClient.getResource(stakeUnitAddress) }
				await send(.internal(.stakeUnitResourceLoaded(result)))
			}.merge(with: .run(operation: { [stakeClaimCollection = state.stake.stakeClaimResource] send in
				guard let stakeClaimCollection else {
					return
				}
				try await Task.sleep(for: .seconds(2))
				let result = await TaskResult { try await onLedgerEntitiesClient.getNonFungibleTokenData(
					.init(
						atLedgerState: stakeClaimCollection.atLedgerState,
						resource: stakeClaimCollection.resourceAddress,
						nonFungibleIds: stakeClaimCollection.nonFungibleIds
					))
				}
				await send(.internal(.stakeClaimNftsLoaded(result)))
			}))
		case .didTap:
			if state.isStakeSelected != nil {
				state.isStakeSelected?.toggle()

				return .none
			} else {
				guard
					let resource = state.stakeResource.wrappedValue,
					let stakeAmount = state.stake.stakeUnitResource?.amount,
					let xrdRedemptionValue = state.xrdRedemptionValue.wrappedValue
				else {
					logger.fault("We should not be able to tap a stake in such state")

					return .none
				}

				state.destination = .details(
					.init(
						validator: state.stake.validator,
						stakeUnitResource: resource,
						stakeAmount: stakeAmount,
						xrdRedemptionValue: xrdRedemptionValue
					)
				)

				return .none
			}
		case let .didTapStakeClaimNFT(withID: id):
			guard let token = state.stakeClaimNfts.wrappedValue?.first(where: { $0.id == id }) else {
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

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .stakeUnitResourceLoaded(.success(resource)):
			state.stakeResource = .success(resource)
			return .none
		case let .stakeUnitResourceLoaded(.failure(err)):
			state.stakeResource = .failure(err)
			return .none
		case let .stakeClaimNftsLoaded(.success(tokens)):
			state.stakeClaimNfts = .success(tokens)
			return .none
		case let .stakeClaimNftsLoaded(.failure(err)):
			state.stakeClaimNfts = .failure(err)
			return .none
		}
	}
}

extension LSUStake.State {
	var xrdRedemptionValue: Loadable<BigDecimal> {
		stakeResource.map {
			((stake.stakeUnitResource?.amount ?? .zero) * stake.validator.xrdVaultBalance) / ($0.totalSupply ?? .one)
		}
	}
}
