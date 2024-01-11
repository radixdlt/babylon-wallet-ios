// MARK: - StakeUnitList
public struct StakeUnitList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let account: OnLedgerEntity.Account
		var stakeSummary: StakeSummaryView.ViewState
		var stakedValidators: IdentifiedArrayOf<ValidatorStakeView.ViewState>
		var selectedLiquidStakeUnits: IdentifiedArrayOf<OnLedgerEntity.OwnedFungibleResource>?
		var selectedStakeClaimTokens: [OnLedgerEntity.OwnedNonFungibleResource: IdentifiedArrayOf<OnLedgerEntity.NonFungibleToken>]?
		var stakeDetails: Loadable<IdentifiedArrayOf<OnLedgerEntitiesClient.OwnedStakeDetails>> = .idle
		var shouldRefresh = false

		@PresentationState
		var destination: Destination.State?

		init(
			account: OnLedgerEntity.Account,
			selectedLiquidStakeUnits: IdentifiedArrayOf<OnLedgerEntity.OwnedFungibleResource>?,
			selectedStakeClaimTokens: [OnLedgerEntity.OwnedNonFungibleResource: IdentifiedArrayOf<OnLedgerEntity.NonFungibleToken>]?
		) {
			self.account = account
			self.selectedLiquidStakeUnits = selectedLiquidStakeUnits
			self.selectedStakeClaimTokens = selectedStakeClaimTokens
			self.stakeSummary = .init(staked: .loading, unstaking: .loading, readyToClaim: .loading)
			self.stakedValidators = account.poolUnitResources.radixNetworkStakes.map {
				ValidatorStakeView.ViewState(id: $0.validatorAddress, content: .loading)
			}.asIdentifiable()
		}
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
				let stakedValidator = state.stakedValidators[id: address]
				guard case var .success(content) = stakedValidator?.content else {
					return .none
				}

				content.liquidStakeUnit?.isSelected?.toggle()

				state.stakedValidators[id: address]?.content = .success(content)

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
			      let ownedStakeClaim = state.account.poolUnitResources.radixNetworkStakes[id: validatorAddress]?.stakeClaimResource,
			      let token = stakeClaimTokens.allTokens[id: id]
			else {
				return .none
			}

			if state.selectedStakeClaimTokens != nil {
				let stakedValidator = state.stakedValidators[id: validatorAddress]
				guard case var .success(content) = stakedValidator?.content else {
					return .none
				}

				content.stakeClaimNFTs?.sections.mutateAll {
					$0.stakeClaims[id: id]?.isSelected?.toggle()
				}
				state.selectedStakeClaimTokens?[ownedStakeClaim, default: []].toggle(token)

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
			updateAfterLoading(&state, details: details.asIdentifiable())
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

extension StakeUnitList {
	private func updateAfterLoading(
		_ state: inout State,
		details: IdentifiedArrayOf<OnLedgerEntitiesClient.OwnedStakeDetails>
	) {
		func processStakeTokens(
			_ stakeClaimTokens: IdentifiedArrayOf<OnLedgerEntity.NonFungibleToken>,
			_ amount: inout RETDecimal
		) -> IdentifiedArrayOf<StakeClaimNFTSView.StakeClaim> {
			var stakeClaims: IdentifiedArrayOf<StakeClaimNFTSView.StakeClaim> = []
			for token in stakeClaimTokens {
				guard let claimAmount = token.data?.claimAmount, claimAmount > .zero() else {
					continue
				}
				amount = amount + claimAmount
				stakeClaims.append(.init(
					id: token.id,
					worth: claimAmount,
					isSelected: state.selectedStakeClaimTokens?.contains(token)
				))
			}

			return stakeClaims
		}

		var stakedAmount: RETDecimal = .zero()
		var unstakingAmount: RETDecimal = .zero()
		var readyToClaimAmount: RETDecimal = .zero()
		var validatorStakes: IdentifiedArrayOf<ValidatorStakeView.ViewState> = []

		for stake in details {
			let stakeXRDRedemptionValue = stake.xrdRedemptionValue
			stakedAmount = stakedAmount + stakeXRDRedemptionValue

			var stakeClaimNFTsViewState: StakeClaimNFTSView.ViewState?

			if let stakeClaimTokens = stake.stakeClaimTokens {
				let unstakingTokens = processStakeTokens(stakeClaimTokens.unstaking, &unstakingAmount)
				let readyToClaimTokens = processStakeTokens(stakeClaimTokens.readyToClaim, &readyToClaimAmount)
				var sections: IdentifiedArrayOf<StakeClaimNFTSView.Section> = []
				if !unstakingTokens.isEmpty {
					sections.append(.init(id: .unstaking, stakeClaims: unstakingTokens))
				}
				if !readyToClaimTokens.isEmpty {
					sections.append(.init(id: .readyToBeClaimed, stakeClaims: readyToClaimTokens))
				}
				stakeClaimNFTsViewState = StakeClaimNFTSView.ViewState(resource: stakeClaimTokens.resource, sections: sections)
			}

			let content = ValidatorStakeView.ViewState.Content(
				validatorNameViewState: .init(imageURL: stake.validator.metadata.iconURL, name: stake.validator.metadata.name ?? L10n.Account.PoolUnits.unknownValidatorName, stakedAmount: stakeXRDRedemptionValue),
				liquidStakeUnit: stake.stakeUnitResource.map { stakeUnitResource in
					.init(
						resource: stakeUnitResource.resource,
						worth: stakeXRDRedemptionValue,
						isSelected: state.selectedLiquidStakeUnits?.contains { $0.id == stakeUnitResource.resource.resourceAddress }
					)
				},
				stakeClaimNFTs: stakeClaimNFTsViewState
			)

			let validatorStake = ValidatorStakeView.ViewState(id: stake.validator.address, content: .success(content))
			validatorStakes.append(validatorStake)
		}

		state.stakeSummary = .init(
			staked: .success(stakedAmount),
			unstaking: .success(unstakingAmount),
			readyToClaim: .success(readyToClaimAmount)
		)

		state.stakedValidators = validatorStakes
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
