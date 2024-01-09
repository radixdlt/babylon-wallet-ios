extension StakeUnitList.State {
	var viewState: StakeUnitList.ViewState {
		guard case let .success(stakesDetail) = stakeDetails else {
			// Loading state
			return .init(
				stakeSummary: .init(staked: .loading, unstaking: .loading, readyToClaim: .loading),
				stakedValidators: account.poolUnitResources.radixNetworkStakes.map {
					ValidatorStakeView.ViewState(id: $0.validatorAddress, content: .loading)
				}.asIdentifiable()
			)
		}
		return processStakesDetail(stakesDetail)
	}

	fileprivate func processStakeTokens(
		_ stakeClaimTokens: IdentifiedArrayOf<OnLedgerEntity.NonFungibleToken>,
		_ amount: inout RETDecimal
	) -> IdentifiedArrayOf<StakeClaimNFTSView.StakeClaim> {
		var stakeClaims: IdentifiedArrayOf<StakeClaimNFTSView.StakeClaim> = []
		for token in stakeClaimTokens {
			guard let claimAmount = token.data?.claimAmount, claimAmount > .zero() else {
				continue
			}
			amount = amount + claimAmount
			stakeClaims.append(.init(id: token.id, worth: claimAmount))
		}

		return stakeClaims
	}

	fileprivate func processStakesDetail(_ stakesDetail: IdentifiedArrayOf<OnLedgerEntitiesClient.OwnedStakeDetails>) -> StakeUnitList.ViewState {
		var stakedAmount: RETDecimal = .zero()
		var unstakingAmount: RETDecimal = .zero()
		var readyToClaimAmount: RETDecimal = .zero()
		var validatorStakes: IdentifiedArrayOf<ValidatorStakeView.ViewState> = []

		for stake in stakesDetail {
			let stakeXRDRedemptionValue = stake.xrdRedemptionValue
			stakedAmount = stakedAmount + stakeXRDRedemptionValue

			var stakeClaimNFTsViewState: StakeClaimNFTSView.ViewState?

			if let stakeClaimTokens = stake.stakeClaimTokens {
				let unstakingTokens = processStakeTokens(stakeClaimTokens.unstaking, &unstakingAmount)
				let readyToClaimTokens = processStakeTokens(stakeClaimTokens.readyToClaim, &readyToClaimAmount)
				var sections: IdentifiedArrayOf<StakeClaimNFTSView.Section> = []
				if !unstakingTokens.isEmpty {
					sections.append(.unstaking(unstakingTokens))
				}
				if !readyToClaimTokens.isEmpty {
					sections.append(.readyToBeClaimed(readyToClaimTokens))
				}
				stakeClaimNFTsViewState = StakeClaimNFTSView.ViewState(resource: stakeClaimTokens.resource, sections: sections)
			}

			let content = ValidatorStakeView.ViewState.Content(
				validatorNameViewState: .init(imageURL: stake.validator.metadata.iconURL, name: stake.validator.metadata.name ?? L10n.Account.PoolUnits.unknownValidatorName, stakedAmount: stakeXRDRedemptionValue),
				liquidStakeUnit: stake.stakeUnitResource.map { .init(resource: $0.resource, worth: stakeXRDRedemptionValue) },
				stakeClaimNFTs: stakeClaimNFTsViewState
			)

			let validatorStake = ValidatorStakeView.ViewState(id: stake.validator.address, content: .success(content))
			validatorStakes.append(validatorStake)
		}

		return .init(
			stakeSummary: .init(
				staked: .success(stakedAmount),
				unstaking: .success(unstakingAmount),
				readyToClaim: .success(readyToClaimAmount)
			),
			stakedValidators: validatorStakes
		)
	}
}

// MARK: - StakeUnitList.View

public extension StakeUnitList {
	struct ViewState: Equatable {
		let stakeSummary: StakeSummaryView.ViewState
		let stakedValidators: IdentifiedArrayOf<ValidatorStakeView.ViewState>
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<StakeUnitList>

		public init(store: StoreOf<StakeUnitList>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState) { viewStore in
				Section {
					StakeSummaryView(viewState: viewStore.stakeSummary) {}
						.rowStyle()
						.padding(.medium1)
				}

				ForEach(viewStore.stakedValidators) { viewState in
					ValidatorStakeView(
						viewState: viewState,
						onLiquidStakeUnitTapped: {
							viewStore.send(.view(.didTapLiquidStakeUnit(forValidator: viewState.id)))
						},
						onStakeClaimTokenTapped: { id in
							viewStore.send(.view(.didTapStakeClaimNFT(forValidator: viewState.id, id: id)))
						}
					)
				}
			}
			.onAppear {
				store.send(.view(.appeared))
			}
			.destinations(with: store)
		}
	}
}

private extension StoreOf<StakeUnitList> {
	var destination: PresentationStoreOf<StakeUnitList.Destination> {
		func scopeState(state: State) -> PresentationState<StakeUnitList.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<StakeUnitList>) -> some View {
		let destinationStore = store.destination
		return lsuDetails(with: destinationStore)
			.stakeClaimNFTDetails(with: destinationStore)
	}

	private func lsuDetails(with destinationStore: PresentationStoreOf<StakeUnitList.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /StakeUnitList.Destination.State.details,
			action: StakeUnitList.Destination.Action.details,
			content: { LSUDetails.View(store: $0) }
		)
	}

	private func stakeClaimNFTDetails(with destinationStore: PresentationStoreOf<StakeUnitList.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /StakeUnitList.Destination.State.stakeClaimDetails,
			action: StakeUnitList.Destination.Action.stakeClaimDetails,
			content: { NonFungibleTokenDetails.View(store: $0) }
		)
	}
}
