// MARK: - StakeUnitList
public struct StakeUnitList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let account: OnLedgerEntity.Account
		var selectedLiquidStakeUnits: IdentifiedArrayOf<OnLedgerEntity.OwnedFungibleResource>?
		var selectedStakeClaimTokens: IdentifiedArrayOf<OnLedgerEntity.NonFungibleToken>?
		var stakeDetails: Loadable<IdentifiedArrayOf<OnLedgerEntitiesClient.OwnedStakeDetails>> = .idle
		var shouldRefresh = false

		@PresentationState
		var destination: Destination.State?
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case refresh
		case didTapLiquidStakeUnit(forValidator: ValidatorAddress)
		case didTapStakeClaimNFT(forValidator: ValidatorAddress, id: NonFungibleGlobalId)
	}

	public enum InternalAction: Sendable, Equatable {
		case detailsLoaded(TaskResult<[OnLedgerEntitiesClient.OwnedStakeDetails]>)
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

	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			guard !state.stakeDetails.isSuccess else {
				return .none
			}

			return loadStakingDetails(&state)

		case .refresh:
			return loadStakingDetails(&state)

		case let .didTapLiquidStakeUnit(address):
			if state.selectedLiquidStakeUnits != nil {
				guard let resource = state.account.poolUnitResources.radixNetworkStakes[id: address]?.stakeUnitResource else {
					return .none
				}

				state.selectedLiquidStakeUnits?.toggle(resource)
				return .none
			} else {
				guard case let .success(stakeDetails) = state.stakeDetails,
				      let stake = stakeDetails[id: address],
				      let stakeUnitResource = stake.stakeUnitResource
				else {
					return .none
				}
				state.destination = .details(
					.init(
						validator: stake.validator,
						stakeUnitResource: stakeUnitResource,
						xrdRedemptionValue: stake.xrdRedemptionValue
					)
				)
			}

			return .none

		case let .didTapStakeClaimNFT(validatorAddress, id):
			guard case let .success(stakeDetails) = state.stakeDetails,
			      let stake = stakeDetails[id: validatorAddress],
			      let stakeClaimTokens = stake.stakeClaimTokens,
			      let token = stakeClaimTokens.allTokens[id: id]
			else {
				return .none
			}

			if state.selectedStakeClaimTokens != nil {
				state.selectedStakeClaimTokens?.toggle(token)
				return .none
			}
			state.destination = .stakeClaimDetails(.init(
				resourceAddress: stakeClaimTokens.resource.resourceAddress,
				resourceDetails: .success(stakeClaimTokens.resource),
				token: token,
				ledgerState: stakeClaimTokens.resource.atLedgerState
			))
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .detailsLoaded(.success(details)):
			state.shouldRefresh = false
			state.stakeDetails = .success(details.asIdentifiable())

			return .none
		case let .detailsLoaded(.failure(error)):
			state.stakeDetails = .failure(error)
			errorQueue.schedule(error)
			return .none
		}
	}

	private func loadStakingDetails(_ state: inout State) -> Effect<Action> {
		state.stakeDetails = .loading

		return .run { [state = state] send in
			let result = await TaskResult {
				try await onLedgerEntitiesClient.getOwnedStakesDetails(
					account: state.account,
					cachingStrategy: state.shouldRefresh ? .forceUpdate : .useCache
				)
			}
			await send(.internal(.detailsLoaded(result)))
		}
	}
}

// MARK: - OnLedgerEntitiesClient.OwnedStakeDetails + Identifiable
extension OnLedgerEntitiesClient.OwnedStakeDetails: Identifiable {
	public var id: ValidatorAddress {
		validator.address
	}
}

extension OnLedgerEntitiesClient.NonFunbileResourceWithTokens {
	var allTokens: IdentifiedArrayOf<OnLedgerEntity.NonFungibleToken> {
		unstaking + readyToClaim
	}
}

extension OnLedgerEntitiesClient.OwnedStakeDetails {
	var xrdRedemptionValue: RETDecimal {
		((stakeUnitResource?.amount ?? 0) * validator.xrdVaultBalance) / (stakeUnitResource?.resource.totalSupply ?? 1)
	}
}
