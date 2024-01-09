extension StakeUnitList.State {
	var viewState: StakeUnitList.ViewState {
		let totalStaked = stakeDetails.map {
			var staked: RETDecimal = .zero()
			for stake in $0 {
				staked = staked + stake.xrdRedemptionValue
			}
			return staked
		}

		let unstaking = stakeDetails.map {
			var unstaking: RETDecimal = .zero()
			for stakeClaim in $0.compactMap(\.stakeClaimTokens) {
				for token in stakeClaim.unstaking {
					unstaking = unstaking + (token.data?.claimAmount ?? .zero())
				}
			}
			return unstaking
		}
		let stakeClaim = stakeDetails.map {
			var unstaking: RETDecimal = .zero()
			for stakeClaim in $0.compactMap(\.stakeClaimTokens) {
				for token in stakeClaim.readyToClaim {
					unstaking = unstaking + (token.data?.claimAmount ?? .zero())
				}
			}
			return unstaking
		}

		let stakedValidators = stakeDetails.map { stakes in
			stakes.map { stake in
				let content = ValidatorStakeView.ViewState.Content(
					validatorNameViewState: .init(imageURL: stake.validator.metadata.iconURL, name: stake.validator.metadata.name ?? L10n.Account.PoolUnits.unknownValidatorName, stakedAmount: stake.xrdRedemptionValue),
					liquidStakeUnit: stake.stakeUnitResource.map { .init(resource: $0.resource, worth: stake.xrdRedemptionValue) },
					stakeClaimNFTs: stake.stakeClaimTokens.map {
						var sections: IdentifiedArrayOf<StakeClaimNFTSView.Section> = []
						if !$0.unstaking.isEmpty {
							sections.append(.unstaking($0.unstaking.map { StakeClaimNFTSView.StakeClaim(id: $0.id, worth: $0.data?.claimAmount ?? .zero()) }.asIdentifiable()))
						}
						if !$0.readyToClaim.isEmpty {
							sections.append(.readyToBeClaimed($0.readyToClaim.map { StakeClaimNFTSView.StakeClaim(id: $0.id, worth: $0.data?.claimAmount ?? .zero()) }.asIdentifiable()))
						}
						return .init(resource: $0.resource, sections: sections)
					}
				)

				return ValidatorStakeView.ViewState(id: stake.validator.address, content: .success(content))
			}.asIdentifiable()
		}
		return .init(stakeSummary: .init(staked: totalStaked, unstaking: unstaking, readyToClaim: stakeClaim), stakedValidators: stakedValidators)
	}
}

// MARK: - StakeUnitList.View

public extension StakeUnitList {
	struct ViewState: Equatable {
		let stakeSummary: StakeSummaryView.ViewState
		let stakedValidators: Loadable<IdentifiedArrayOf<ValidatorStakeView.ViewState>>
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

				loadable(viewStore.stakedValidators) {
					ForEach($0) { viewState in
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
