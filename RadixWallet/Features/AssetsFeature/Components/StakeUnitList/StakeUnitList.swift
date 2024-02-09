// MARK: - StakeUnitList
public struct StakeUnitList: Sendable, FeatureReducer {
	typealias SelectedStakeClaimTokens = [OnLedgerEntity.OwnedNonFungibleResource: IdentifiedArrayOf<OnLedgerEntity.NonFungibleToken>]

	public struct State: Sendable, Hashable {
		let account: OnLedgerEntity.Account
		var ownedStakes: IdentifiedArrayOf<OnLedgerEntity.Account.RadixNetworkStake> {
			account.poolUnitResources.radixNetworkStakes
		}

		// Child states
		var stakeSummary: StakeSummaryView.ViewState
		var stakedValidators: IdentifiedArrayOf<ValidatorStakeView.ViewState>

		// Selection states
		var selectedLiquidStakeUnits: IdentifiedArrayOf<OnLedgerEntity.OwnedFungibleResource>?
		var selectedStakeClaimTokens: SelectedStakeClaimTokens?

		// Loading state
		var isLoading: Bool
		var shouldRefresh: Bool

		@PresentationState
		var destination: Destination.State?

		init(
			account: OnLedgerEntity.Account,
			selectedLiquidStakeUnits: IdentifiedArrayOf<OnLedgerEntity.OwnedFungibleResource>?,
			selectedStakeClaimTokens: SelectedStakeClaimTokens?
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
			self.stakedValidators = []

			self.isLoading = false
			self.shouldRefresh = false
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case refresh
		case didTapLiquidStakeUnit(forValidator: ValidatorAddress)
		case didTapStakeClaimNFT(OnLedgerEntitiesClient.StakeClaim)
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
			guard !state.isLoading else {
				return .none
			}

			return loadStakingDetails(&state)

		case .refresh:
			state.shouldRefresh = true
			return loadStakingDetails(&state)

		case let .didTapLiquidStakeUnit(validatorAddress):
			if state.selectedLiquidStakeUnits != nil {
				guard let resource = state.ownedStakes[id: validatorAddress]?.stakeUnitResource
				else {
					return .none
				}

				state.stakedValidators[id: validatorAddress]?.liquidStakeUnit?.isSelected?.toggle()

				state.selectedLiquidStakeUnits?.togglePresence(of: resource)
				return .none
			} else {
				guard let stakeDetails = state.stakedValidators[id: validatorAddress]?.stakeDetails,
				      let stakeUnitResource = stakeDetails.stakeUnitResource
				else {
					return .none
				}
				state.destination = .details(
					.init(
						validator: stakeDetails.validator,
						stakeUnitResource: stakeUnitResource,
						xrdRedemptionValue: stakeDetails.xrdRedemptionValue
					)
				)
			}

			return .none

		case let .didTapStakeClaimNFT(stakeClaim):
			guard let stakedValidator = state.stakedValidators[id: stakeClaim.validatorAddress] else {
				return .none
			}

			if state.selectedStakeClaimTokens != nil {
				guard let stake = state.ownedStakes[id: stakeClaim.validatorAddress],
				      let ownedStakeClaim = stake.stakeClaimResource
				else {
					return .none
				}

				state.stakedValidators[id: stakeClaim.validatorAddress]?
					.stakeClaimResource?
					.stakeClaimTokens
					.selectedStakeClaims?
					.togglePresence(of: stakeClaim.token.id)
				state.selectedStakeClaimTokens?[ownedStakeClaim, default: []].togglePresence(of: stakeClaim.token)

				return .none
			}

			guard let stakeClaimTokens = stakedValidator.stakeDetails.stakeClaimTokens else {
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
			guard let stakeClaimTokens = state.stakedValidators[id: validatorAddress]?.stakeDetails.stakeClaimTokens,
			      let stakeClaims = stakeClaimTokens.stakeClaims.filter(\.isReadyToBeClaimed).nonEmpty
			else {
				return .none
			}

			return sendStakeClaimTransaction(
				state.account.address,
				stakeClaims: [
					.init(
						validatorAddress: validatorAddress,
						resourceAddress: stakeClaimTokens.resource.resourceAddress,
						ids: stakeClaims.map { $0.id.localId() },
						amount: stakeClaims.map(\.claimAmount).reduce(0, +)
					),
				]
			)

		case .didTapClaimAllStakes:
			return sendStakeClaimTransaction(
				state.account.address,
				stakeClaims: state.stakedValidators.map(\.stakeDetails).compactMap { stake in
					guard let stakeClaimTokens = stake.stakeClaimTokens,
					      let stakeClaims = stakeClaimTokens.stakeClaims.filter(\.isReadyToBeClaimed).nonEmpty
					else {
						return nil
					}

					return .init(
						validatorAddress: stake.validator.address,
						resourceAddress: stakeClaimTokens.resource.resourceAddress,
						ids: stakeClaims.map { $0.id.localId() },
						amount: stakeClaims.map(\.claimAmount).reduce(0, +)
					)
				}
			)
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .detailsLoaded(.success(details)):
			state.isLoading = false
			state.shouldRefresh = false
			updateAfterLoading(&state, details: details.asIdentifiable())
			return .none
		case let .detailsLoaded(.failure(error)):
			state.isLoading = false
			state.shouldRefresh = false
			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .stakeClaimDetails(.delegate(.tappedClaimStake(resourceAddress, stakeClaim))):
			state.destination = nil
			return sendStakeClaimTransaction(
				state.account.address,
				stakeClaims: [
					.init(
						validatorAddress: stakeClaim.validatorAddress,
						resourceAddress: resourceAddress,
						ids: .init(stakeClaim.id.localId()),
						amount: stakeClaim.claimAmount
					),
				]
			)
		case .stakeClaimDetails, .details:
			return .none
		}
	}

	private func loadStakingDetails(_ state: inout State) -> Effect<Action> {
		state.isLoading = true

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
			let manifest = try ManifestBuilder.stakeClaimsManifest(
				accountAddress: acccountAddress,
				stakeClaims: stakeClaims
			)
			_ = try await dappInteractionClient.addWalletInteraction(
				.transaction(.init(send: .init(transactionManifest: manifest))),
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
		let allSelectedTokens = state.selectedStakeClaimTokens?.values.flatMap { $0 }.map(\.id).asIdentifiable()

		let stakeClaims = details.compactMap(\.stakeClaimTokens).flatMap(\.stakeClaims)
		let stakedAmount = details.map(\.xrdRedemptionValue).reduce(.zero, +)
		let unstakingAmount = stakeClaims.filter(not(\.isReadyToBeClaimed)).map(\.claimAmount).reduce(.zero, +)
		let readyToClaimAmount = stakeClaims.filter(\.isReadyToBeClaimed).map(\.claimAmount).reduce(.zero, +)

		let validatorStakes = details.map { stake in
			ValidatorStakeView.ViewState(
				stakeDetails: stake,
				validatorNameViewState: .init(
					imageURL: stake.validator.metadata.iconURL,
					name: stake.validator.metadata.name ?? L10n.Account.PoolUnits.unknownValidatorName,
					stakedAmount: stake.xrdRedemptionValue
				),
				liquidStakeUnit: stake.stakeUnitResource.map { stakeUnitResource in
					.init(
						resource: stakeUnitResource.resource,
						amount: nil,
						guaranteedAmount: nil,
						worth: stake.xrdRedemptionValue,
						isSelected: state.selectedLiquidStakeUnits?.contains { $0.id == stakeUnitResource.resource.resourceAddress }
					)
				},
				stakeClaimResource: stake.stakeClaimTokens.map { stakeClaimTokens in
					StakeClaimResourceView.ViewState(
						canClaimTokens: allSelectedTokens == nil, // cannot claim in selection mode
						stakeClaimTokens: stakeClaimTokens,
						selectedStakeClaims: allSelectedTokens
					)
				}
			)
		}.sorted(by: \.id.address).asIdentifiable()

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
