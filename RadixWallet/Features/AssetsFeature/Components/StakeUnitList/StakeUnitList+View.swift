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
extension StakeUnitList {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<StakeUnitList>

		init(store: StoreOf<StakeUnitList>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				Section {
					StakeSummaryView(viewState: viewStore.stakeSummary) {
						viewStore.send(.view(.didTapClaimAllStakes))
					}
					.rowStyle()
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
			.background(.primaryBackground)
		}

		@ViewBuilder
		private func stakedValidatorsSectionHeader(_ validatorsCount: Int) -> some SwiftUI.View {
			HStack(spacing: .small2) {
				Image(.iconValidator)
					.withDottedCircleOverlay()
				Text(L10n.Account.Staking.stakedValidators(validatorsCount))
					.textStyle(.body1Link)
					.foregroundColor(.secondaryText)
			}
			.rowStyle()
		}
	}
}
