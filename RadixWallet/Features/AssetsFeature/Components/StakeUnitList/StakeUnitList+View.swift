// MARK: - StakeUnitList.View
extension StakeUnitList.State {
	var firstStakedValidator: ValidatorStakeView.ViewState {
		stakedValidators.first!
	}

	var remainingStakedValidators: IdentifiedArrayOf<ValidatorStakeView.ViewState> {
		Array(stakedValidators.dropFirst()).asIdentified()
	}
}

// MARK: - StakeUnitList.View
public extension StakeUnitList {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<StakeUnitList>

		public init(store: StoreOf<StakeUnitList>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				Section {
					StakeSummaryView(viewState: viewStore.stakeSummary) {
						viewStore.send(.view(.didTapClaimAllStakes))
					}
					.rowStyle()
					.padding(.medium1)
				}

				if !viewStore.stakedValidators.isEmpty {
					Section {
						validatorStakeView(viewStore.firstStakedValidator)
					} header: {
						stakedValidatorsSectionHeader(viewStore.ownedStakes.count)
					}

					ForEach(viewStore.remainingStakedValidators) { viewState in
						Section {
							validatorStakeView(viewState)
						}
					}
				} else {
					loadingView(viewStore.ownedStakes)
				}
			}
			.onAppear {
				store.send(.view(.appeared))
			}
			.destinations(with: store)
		}

		@ViewBuilder
		private func loadingView(_ ownedStakes: IdentifiedArrayOf<OnLedgerEntity.OnLedgerAccount.RadixNetworkStake>) -> some SwiftUI.View {
			Section {
				shimmeringLoadingView()
			} header: {
				stakedValidatorsSectionHeader(ownedStakes.count)
			}

			ForEach(ownedStakes.dropFirst()) { _ in
				Section {
					shimmeringLoadingView()
				}
			}
		}

		@ViewBuilder
		private func loadedView(_ ownedStakes: IdentifiedArrayOf<OnLedgerEntity.OnLedgerAccount.RadixNetworkStake>) -> some SwiftUI.View {
			Section {
				shimmeringLoadingView()
			} header: {
				stakedValidatorsSectionHeader(ownedStakes.count)
			}

			ForEach(ownedStakes.dropFirst()) { _ in
				Section {
					shimmeringLoadingView()
				}
			}
		}

		@ViewBuilder
		private func validatorStakeView(_ viewState: ValidatorStakeView.ViewState) -> some SwiftUI.View {
			ValidatorStakeView(
				viewState: viewState,
				onLiquidStakeUnitTapped: {
					store.send(.view(.didTapLiquidStakeUnit(forValidator: viewState.id)))
				},
				onStakeClaimTokenTapped: { claim in
					store.send(.view(.didTapStakeClaimNFT(claim)))
				},
				onClaimAllStakeClaimsTapped: {
					store.send(.view(.didTapClaimAll(forValidator: viewState.id)))
				}
			)
		}

		@ViewBuilder
		private func stakedValidatorsSectionHeader(_ validatorsCount: Int) -> some SwiftUI.View {
			HStack {
				Image(asset: AssetResource.iconValidator).withDottedCircleOverlay()
				Text(L10n.Account.Staking.stakedValidators(validatorsCount))
					.textStyle(.body1Link)
					.foregroundColor(.app.gray2)
			}
			.rowStyle()
			.padding(.bottom, .small2)
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
