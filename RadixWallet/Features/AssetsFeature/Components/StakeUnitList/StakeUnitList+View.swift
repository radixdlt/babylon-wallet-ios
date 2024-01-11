// MARK: - StakeUnitList.View
extension StakeUnitList.State {
	var firstStakedValidator: ValidatorStakeView.ViewState {
		stakedValidators.first!
	}

	var remainingStakedValidators: IdentifiedArrayOf<ValidatorStakeView.ViewState> {
		Array(stakedValidators.dropFirst()).asIdentifiable()
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
					StakeSummaryView(viewState: viewStore.stakeSummary) {}
						.rowStyle()
						.padding(.medium1)
				}

				Section {
					validatorStakeView(viewStore.firstStakedValidator)
				} header: {
					HStack {
						Image(asset: AssetResource.iconValidator).withDottedCircleOverlay()
						Text(L10n.Account.Staking.stakedValidators(viewStore.stakedValidators.count))
							.textStyle(.body1Link)
							.foregroundColor(.app.gray2)
					}
					.rowStyle()
					.padding(.bottom, .small2)
				}

				ForEach(viewStore.remainingStakedValidators) { viewState in
					Section {
						validatorStakeView(viewState)
					}
				}
			}
			.onAppear {
				store.send(.view(.appeared))
			}
			.destinations(with: store)
		}

		@ViewBuilder
		private func validatorStakeView(_ viewState: ValidatorStakeView.ViewState) -> some SwiftUI.View {
			ValidatorStakeView(
				viewState: viewState,
				onLiquidStakeUnitTapped: {
					store.send(.view(.didTapLiquidStakeUnit(forValidator: viewState.id)))
				},
				onStakeClaimTokenTapped: { id in
					store.send(.view(.didTapStakeClaimNFT(forValidator: viewState.id, id: id)))
				}
			)
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
