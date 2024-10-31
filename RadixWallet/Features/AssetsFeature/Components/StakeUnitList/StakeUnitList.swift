// MARK: - StakeUnitList
struct StakeUnitList: Sendable, FeatureReducer {
	typealias SelectedStakeClaimTokens = [OnLedgerEntity.OwnedNonFungibleResource: IdentifiedArrayOf<OnLedgerEntity.NonFungibleToken>]

	struct State: Sendable, Hashable {
		let account: OnLedgerEntity.OnLedgerAccount
		var ownedStakes: IdentifiedArrayOf<OnLedgerEntity.OnLedgerAccount.RadixNetworkStake> {
			account.poolUnitResources.radixNetworkStakes
		}

		// Child states
		var stakeSummary: StakeSummaryView.ViewState
		var stakedValidators: IdentifiedArrayOf<ValidatorStakeView.ViewState>

		// Selection states
		var selectedLiquidStakeUnits: IdentifiedArrayOf<OnLedgerEntity.OwnedFungibleResource>?
		var selectedStakeClaimTokens: SelectedStakeClaimTokens?

		init(
			account: OnLedgerEntity.OnLedgerAccount,
			selectedLiquidStakeUnits: IdentifiedArrayOf<OnLedgerEntity.OwnedFungibleResource>?,
			selectedStakeClaimTokens: SelectedStakeClaimTokens?,
			stakeUnitDetails: Loadable<IdentifiedArrayOf<OnLedgerEntitiesClient.OwnedStakeDetails>>
		) {
			self.account = account
			self.selectedLiquidStakeUnits = selectedLiquidStakeUnits
			self.selectedStakeClaimTokens = selectedStakeClaimTokens

			switch stakeUnitDetails {
			case .idle, .loading:
				self.stakeSummary = .init(
					staked: .loading,
					unstaking: .loading,
					readyToClaim: .loading,
					canClaimStakes: selectedStakeClaimTokens == nil
				)
				self.stakedValidators = []
			case let .success(details):
				let allSelectedTokens = selectedStakeClaimTokens?.values.flatMap { $0 }.map(\.id).asIdentified()

				let stakeClaims = details.compactMap(\.stakeClaimTokens).flatMap(\.stakeClaims)
				let stakedAmount = details.map {
					guard let exactAmount = $0.xrdRedemptionValue.exactAmount?.nominalAmount else {
						fatalError()
					}
					return ExactResourceAmount(
						nominalAmount: exactAmount,
						fiatWorth: $0.stakeUnitResource?.amount.exactAmount!.fiatWorth
					)
				}.reduce(.zero, +)

				let unstakingAmount = stakeClaims.filter(not(\.isReadyToBeClaimed)).map(\.claimAmount)
					.reduce(.zero, +)
				let readyToClaimAmount = stakeClaims.filter(\.isReadyToBeClaimed).map(\.claimAmount)
					.reduce(.zero, +)

				let validatorStakes = details.map { stake in
					guard let xrdRedemptionValue = stake.xrdRedemptionValue.exactAmount?.nominalAmount else {
						fatalError()
					}

					return ValidatorStakeView.ViewState(
						stakeDetails: stake,
						validatorNameViewState: .init(
							imageURL: stake.validator.metadata.iconURL,
							name: stake.validator.metadata.name ?? L10n.Account.PoolUnits.unknownValidatorName,
							stakedAmount: xrdRedemptionValue
						),
						liquidStakeUnit: stake.stakeUnitResource.map { stakeUnitResource in
							.init(
								lsu: .init(
									address: stakeUnitResource.resource.resourceAddress,
									icon: stakeUnitResource.resource.metadata.iconURL,
									title: stakeUnitResource.resource.metadata.title,
									amount: nil,
									worth: .exact(.init(
										nominalAmount: xrdRedemptionValue,
										fiatWorth: stake.stakeUnitResource?.amount.exactAmount!.fiatWorth
									)),
									validatorName: nil
								),
								isSelected: selectedLiquidStakeUnits?.contains { $0.id == stakeUnitResource.resource.resourceAddress }
							)
						},
						stakeClaimResource: stake.stakeClaimTokens.map { stakeClaimTokens in
							KnownResourceBalance.StakeClaimNFT(
								canClaimTokens: allSelectedTokens == nil, // cannot claim in selection mode
								stakeClaimTokens: stakeClaimTokens,
								selectedStakeClaims: allSelectedTokens
							)
						}
					)
				}.sorted(by: \.id.address).asIdentified()

				self.stakeSummary = .init(
					staked: .success(stakedAmount),
					unstaking: .success(unstakingAmount),
					readyToClaim: .success(readyToClaimAmount),
					canClaimStakes: selectedStakeClaimTokens == nil
				)

				self.stakedValidators = validatorStakes
			case .failure:
				self.stakeSummary = .init(
					staked: .loading,
					unstaking: .loading,
					readyToClaim: .loading,
					canClaimStakes: selectedStakeClaimTokens == nil
				)

				self.stakedValidators = []
			}
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case didTapLiquidStakeUnit(forValidator: ValidatorAddress)
		case didTapStakeClaimNFT(OnLedgerEntitiesClient.StakeClaim)
		case didTapClaimAll(forValidator: ValidatorAddress)
		case didTapClaimAllStakes
	}

	enum DelegateAction: Sendable, Equatable {
		case selected(Selection)

		enum Selection: Sendable, Equatable {
			case unit(OnLedgerEntitiesClient.ResourceWithVaultAmount, details: OnLedgerEntitiesClient.OwnedStakeDetails)
			case claim(OnLedgerEntity.Resource, claim: OnLedgerEntitiesClient.StakeClaim)
		}
	}

	@Dependency(\.dappInteractionClient) var dappInteractionClient
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
	@Dependency(\.errorQueue) var errorQueue

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .none

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
				return .send(.delegate(.selected(.unit(stakeUnitResource, details: stakeDetails))))
			}

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
			return .send(.delegate(.selected(.claim(stakeClaimTokens.resource, claim: stakeClaim))))

		case let .didTapClaimAll(validatorAddress):
			guard let stakeClaimTokens = state.stakedValidators[id: validatorAddress]?.stakeDetails.stakeClaimTokens,
			      let stakeClaims = stakeClaimTokens.stakeClaims.filter(\.isReadyToBeClaimed).nonEmpty
			else {
				return .none
			}
			guard let nonFungibleResourceAddress = try? NonFungibleResourceAddress(validatingAddress: stakeClaimTokens.resource.resourceAddress.address) else {
				return .none
			}
			return sendStakeClaimTransaction(
				state.account.address,
				stakeClaims: [
					.init(
						validatorAddress: validatorAddress,
						resourceAddress: nonFungibleResourceAddress,
						ids: stakeClaims.map(\.id.nonFungibleLocalId),
						amount: stakeClaims.map(\.claimAmount.nominalAmount).reduce(0, +)
					),
				]
			)

		case .didTapClaimAllStakes:
			return sendStakeClaimTransaction(
				state.account.address,
				stakeClaims: state.stakedValidators.map(\.stakeDetails).compactMap { stake -> StakeClaim? in
					guard let stakeClaimTokens = stake.stakeClaimTokens,
					      let stakeClaims = stakeClaimTokens.stakeClaims.filter(\.isReadyToBeClaimed).nonEmpty
					else {
						return nil
					}

					guard let nonFungibleResourceAddress = try? NonFungibleResourceAddress(validatingAddress: stakeClaimTokens.resource.resourceAddress.address) else {
						return nil
					}

					return .init(
						validatorAddress: stake.validator.address,
						resourceAddress: nonFungibleResourceAddress,
						ids: stakeClaims.map(\.id.nonFungibleLocalId),
						amount: stakeClaims.map(\.claimAmount.nominalAmount).reduce(0, +)
					)
				}
			)
		}
	}

	private func sendStakeClaimTransaction(
		_ acccountAddress: AccountAddress,
		stakeClaims: [StakeClaim]
	) -> Effect<Action> {
		.run { _ in
			let manifest = TransactionManifest.stakesClaim(
				accountAddress: acccountAddress,
				stakeClaims: stakeClaims
			)
			_ = await dappInteractionClient.addWalletInteraction(
				.transaction(.init(send: .init(transactionManifest: manifest))),
				.accountTransfer
			)
		}
	}
}

// MARK: - OnLedgerEntitiesClient.OwnedStakeDetails + Identifiable
extension OnLedgerEntitiesClient.OwnedStakeDetails: Identifiable {
	var id: ValidatorAddress {
		validator.address
	}
}

extension OnLedgerEntitiesClient.OwnedStakeDetails {
	var xrdRedemptionValue: ResourceAmount {
		stakeUnitResource?.amount.adjustedNominalAmount { xrdRedemptionValue(exactAmount: .init(nominalAmount: $0)).nominalAmount } ?? .exact(.zero)
	}

	func xrdRedemptionValue(exactAmount: ExactResourceAmount) -> ExactResourceAmount {
		.init(nominalAmount: (exactAmount.nominalAmount * validator.xrdVaultBalance) / (stakeUnitResource?.resource.totalSupply ?? 1))
	}
}
