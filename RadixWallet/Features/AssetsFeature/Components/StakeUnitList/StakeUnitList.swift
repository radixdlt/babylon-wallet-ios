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
			self.stakeSummary = .init(
				staked: .loading,
				unstaking: .loading,
				readyToClaim: .loading,
				canClaimStakes: selectedStakeClaimTokens == nil
			)
			self.stakedValidators = account.poolUnitResources.radixNetworkStakes.map {
				ValidatorStakeView.ViewState(id: $0.validatorAddress, content: .loading)
			}.asIdentifiable()
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case refresh
		case didTapLiquidStakeUnit(forValidator: ValidatorAddress)
		case didTapStakeClaimNFT(forValidator: ValidatorAddress, claim: OnLedgerEntitiesClient.StakeClaim)
		case didTapClaimAll(forValidator: ValidatorAddress)
		case didTapClaimAllStakes
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

	@Dependency(\.dappInteractionClient) var dappInteractionClient
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
				guard case var .success(content) = stakedValidator?.content,
				      let resource = state.account.poolUnitResources.radixNetworkStakes[id: address]?.stakeUnitResource
				else {
					return .none
				}

				content.liquidStakeUnit?.isSelected?.toggle()
				state.stakedValidators[id: address]?.content = .success(content)

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

		case let .didTapStakeClaimNFT(validatorAddress, stakeClaim):
			guard case let .success(stakeDetails) = state.stakeDetails,
			      let stake = state.account.poolUnitResources.radixNetworkStakes[id: validatorAddress],
			      let stakeDetails = stakeDetails[id: validatorAddress],
			      let stakeClaimTokens = stakeDetails.stakeClaimTokens,
			      let ownedStakeClaim = stake.stakeClaimResource
			else {
				return .none
			}

			if state.selectedStakeClaimTokens != nil {
				let stakedValidator = state.stakedValidators[id: stakeClaim.validatorAddress]
				guard case var .success(content) = stakedValidator?.content else {
					return .none
				}

				content.stakeClaimNFTs?.selectedStakeClaims?.toggle(stakeClaim.token.id)

				state.stakedValidators[id: validatorAddress]?.content = .success(content)
				state.selectedStakeClaimTokens?[ownedStakeClaim, default: []].toggle(stakeClaim.token)

				return .none
			}

			state.destination = .stakeClaimDetails(.init(
				resourceAddress: stakeClaimTokens.resource.resourceAddress,
				resourceDetails: .success(stakeClaimTokens.resource),
				token: stakeClaim.token,
				ledgerState: stakeClaimTokens.resource.atLedgerState,
				stakeClaim: stakeClaim
			))
			return .none

		case let .didTapClaimAll(validatorAddress):
			guard case let .success(stakeDetails) = state.stakeDetails,
			      let stakeClaim = stakeDetails[id: validatorAddress]?.stakeClaimTokens
			else {
				return .none
			}

			return sendStakeClaimTransaction(
				state.account.address,
				stakeClaims: [
					.init(
						validatorAddress: validatorAddress,
						resourceAddress: stakeClaim.resource.resourceAddress,
						ids: stakeClaim.stakeClaims.filter(\.isReadyToBeClaimed).map { $0.id.localId() }
					),
				]
			)

		case .didTapClaimAllStakes:
			guard case let .success(stakeDetails) = state.stakeDetails else {
				return .none
			}

			return sendStakeClaimTransaction(
				state.account.address,
				stakeClaims: stakeDetails.compactMap { stake in
					guard let stakeClaimTokens = stake.stakeClaimTokens,
					      let stakeClaims = stakeClaimTokens.stakeClaims.filter(\.isReadyToBeClaimed).nilIfEmpty
					else {
						return nil
					}

					return .init(
						validatorAddress: stake.validator.address,
						resourceAddress: stakeClaimTokens.resource.resourceAddress,
						ids: stakeClaims.map { $0.id.localId() }
					)
				}
			)
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

//	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
//		switch presentedAction {
//		case let .stakeClaimDetails(.delegate(.tappedClaimStake(id, stakeClaim))):
//			try! sendStakeClaimTransaction(
//				state.account.address,
//				stakeClaims: [
//					.init(
//						validatorAddress: stakeClaim.validatorAddress,
//						resourceAddress: id.resourceAddress().asSpecific(),
//						ids: [id.localId()]
//					),
//				]
//			)
//		case .stakeClaimDetails, .details:
//			.none
//		}
//	}

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

	private func sendStakeClaimTransaction(_ acccountAddress: AccountAddress, stakeClaims: [ManifestBuilder.StakeClaim]) -> Effect<Action> {
		.run { _ in
			let manifest = try ManifestBuilder.stakeClaimManifest(
				accountAddress: acccountAddress,
				stakeClaims: stakeClaims,
				networkId: acccountAddress.intoEngine().networkId()
			)
			_ = await dappInteractionClient.addWalletInteraction(
				.transaction(.init(
					send: .init(
						version: .default,
						transactionManifest: manifest,
						message: ""
					)
				)),
				.accountTransfer
			)
		}
	}
}

extension StakeUnitList {
	private func updateAfterLoading(
		_ state: inout State,
		details: IdentifiedArrayOf<OnLedgerEntitiesClient.OwnedStakeDetails>
	) {
		let allSelectedTokens = state.selectedStakeClaimTokens?.values.flatMap { $0 }
		let stakeClaims = details.compactMap(\.stakeClaimTokens).flatMap(\.stakeClaims)

		let stakedAmount = details.map(\.xrdRedemptionValue).reduce(.zero(), +)
		let unstakingAmount = stakeClaims.filter(not(\.isReadyToBeClaimed)).map(\.claimAmount).reduce(.zero(), +)
		let readyToClaimAmount = stakeClaims.filter(\.isReadyToBeClaimed).map(\.claimAmount).reduce(.zero(), +)
		let validatorStakes = details.map { stake in
			let content = ValidatorStakeView.ViewState.Content(
				validatorNameViewState: .init(
					imageURL: stake.validator.metadata.iconURL,
					name: stake.validator.metadata.name ?? L10n.Account.PoolUnits.unknownValidatorName,
					stakedAmount: stake.xrdRedemptionValue
				),
				liquidStakeUnit: stake.stakeUnitResource.map { stakeUnitResource in
					.init(
						resource: stakeUnitResource.resource,
						worth: stake.xrdRedemptionValue,
						isSelected: state.selectedLiquidStakeUnits?.contains { $0.id == stakeUnitResource.resource.resourceAddress }
					)
				},
				stakeClaimNFTs: stake.stakeClaimTokens.map { stakeClaimTokens in
					StakeClaimNFTSView.ViewState(stakeClaimTokens: stakeClaimTokens, selectedStakeClaims: nil)
				}
			)

			return ValidatorStakeView.ViewState(id: stake.validator.address, content: .success(content))
		}.asIdentifiable()

		state.stakeSummary = .init(
			staked: .success(stakedAmount),
			unstaking: .success(unstakingAmount),
			readyToClaim: .success(readyToClaimAmount),
			canClaimStakes: state.selectedStakeClaimTokens == nil
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

extension OnLedgerEntitiesClient.OwnedStakeDetails {
	var xrdRedemptionValue: RETDecimal {
		((stakeUnitResource?.amount ?? 0) * validator.xrdVaultBalance) / (stakeUnitResource?.resource.totalSupply ?? 1)
	}
}
