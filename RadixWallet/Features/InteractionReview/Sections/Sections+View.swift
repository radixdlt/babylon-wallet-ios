import SwiftUI

// MARK: - InteractionReview.Sections.View
extension InteractionReview.Sections {
	struct View: SwiftUI.View {
		let store: StoreOf<InteractionReview.Sections>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(alignment: .leading, spacing: .medium1) {
					withdrawals

					VStack(alignment: .leading, spacing: .medium1) {
						contributingToPools
						redeemingFromPools

						stakingToValidators
						unstakingFromValidators
						claimingFromValidators

						dAppsUsed

						deposits
					}
					.frame(maxWidth: .infinity, alignment: .leading) // necessary?
					.background(alignment: .trailing) {
						if store.showTransferLine {
							Common.TransferLineView()
						}
					}

					accountDepositSetting
					accountDepositExceptions
				}
				.animation(.easeInOut, value: store.contributingToPools?.isExpanded)
				.animation(.easeInOut, value: store.redeemingFromPools?.isExpanded)
				.animation(.easeInOut, value: store.stakingToValidators?.isExpanded)
				.animation(.easeInOut, value: store.unstakingFromValidators?.isExpanded)
				.animation(.easeInOut, value: store.claimingFromValidators?.isExpanded)
				.animation(.easeInOut, value: store.dAppsUsed?.isExpanded)
			}
			.destinations(with: store)
		}

		@ViewBuilder
		private var withdrawals: some SwiftUI.View {
			if let childStore = store.scope(state: \.withdrawals, action: \.child.withdrawals) {
				VStack(alignment: .leading, spacing: .small2) {
					Common.HeadingView.withdrawing
					Common.Accounts.View(store: childStore)
				}
			}
		}

		@ViewBuilder
		private var contributingToPools: some SwiftUI.View {
			if let childStore = store.scope(state: \.contributingToPools, action: \.child.contributingToPools) {
				VStack(alignment: .leading, spacing: .small2) {
					let isExpanded = childStore.isExpanded
					Common.ExpandableHeadingView(heading: .contributingToPools, isExpanded: isExpanded) {
//						store.send(.view(.expandContributingToPoolsTapped))
					}
					if isExpanded {
						InteractionReviewPools.View(store: childStore)
							.transition(.opacity.combined(with: .scale(scale: 0.95)))
					}
				}
			}
		}

		@ViewBuilder
		private var redeemingFromPools: some SwiftUI.View {
			if let childStore = store.scope(state: \.redeemingFromPools, action: \.child.redeemingFromPools) {
				VStack(alignment: .leading, spacing: .small2) {
					let isExpanded = childStore.isExpanded
					Common.ExpandableHeadingView(heading: .redeemingFromPools, isExpanded: isExpanded) {
//						store.send(.view(.expandRedeemingFromPoolsTapped))
					}
					if isExpanded {
						InteractionReviewPools.View(store: childStore)
							.transition(.opacity.combined(with: .scale(scale: 0.95)))
					}
				}
			}
		}

		@ViewBuilder
		private var stakingToValidators: some SwiftUI.View {
			if let viewState = store.stakingToValidators {
				Common.ValidatorsView(heading: .stakingToValidators, viewState: viewState) {
//					store.send(.view(.expandStakingToValidatorsTapped))
				}
			}
		}

		@ViewBuilder
		private var unstakingFromValidators: some SwiftUI.View {
			if let viewState = store.unstakingFromValidators {
				Common.ValidatorsView(heading: .unstakingFromValidators, viewState: viewState) {
//					store.send(.view(.expandUnstakingFromValidatorsTapped))
				}
			}
		}

		@ViewBuilder
		private var claimingFromValidators: some SwiftUI.View {
			if let viewState = store.claimingFromValidators {
				Common.ValidatorsView(heading: .claimingFromValidators, viewState: viewState) {
//					store.send(.view(.expandClaimingFromValidatorsTapped))
				}
			}
		}

		@ViewBuilder
		private var accountDepositSetting: some SwiftUI.View {
			if let viewState = store.accountDepositSetting {
				VStack(alignment: .leading, spacing: .small2) {
					Common.HeadingView.depositSetting
					Common.DepositSettingView(viewState: viewState)
				}
			}
		}

		@ViewBuilder
		private var accountDepositExceptions: some SwiftUI.View {
			if let viewState = store.accountDepositExceptions {
				VStack(alignment: .leading, spacing: .small2) {
					Common.HeadingView.depositExceptions
					Common.DepositExceptionsView(viewState: viewState)
				}
			}
		}

		@ViewBuilder
		private var dAppsUsed: some SwiftUI.View {
			if let childStore = store.scope(state: \.dAppsUsed, action: \.child.dAppsUsed) {
				VStack(alignment: .leading, spacing: .small2) {
					let isExpanded = childStore.isExpanded
					Common.ExpandableHeadingView(heading: .usingDapps, isExpanded: isExpanded) {
//						store.send(.view(.expandDappsUsedTapped))
					}
					if isExpanded {
						InteractionReviewDappsUsed.View(store: childStore)
							.transition(.opacity.combined(with: .scale(scale: 0.95)))
					}
				}
			}
		}

		@ViewBuilder
		private var deposits: some SwiftUI.View {
			if let childStore = store.scope(state: \.deposits, action: \.child.deposits) {
				VStack(alignment: .leading, spacing: .small2) {
					Common.HeadingView.depositing
					Common.Accounts.View(store: childStore)
				}
			}
		}
	}
}

extension InteractionReview.Sections.State {
	var showTransferLine: Bool {
		withdrawals != nil && deposits != nil
	}
}

extension StoreOf<InteractionReview.Sections> {
	var destination: PresentationStoreOf<InteractionReview.Sections.Destination> {
		func scopeState(state: State) -> PresentationState<InteractionReview.Sections.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	typealias Destination = InteractionReview.Sections.Destination

	func destinations(with store: StoreOf<InteractionReview.Sections>) -> some View {
		let destinationStore = store.destination
		return dApp(with: destinationStore)
			.fungibleTokenDetails(with: destinationStore)
			.nonFungibleTokenDetails(with: destinationStore)
			.lsuDetails(with: destinationStore)
			.poolUnitDetails(with: destinationStore)
			.unknownComponents(with: destinationStore)
			.rawTransactionAlert(with: destinationStore)
	}

	private func rawTransactionAlert(with destinationStore: PresentationStoreOf<Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.rawTransactionAlert, action: \.rawTransactionAlert))
	}

	private func dApp(with destinationStore: PresentationStoreOf<Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.dApp, action: \.dApp)) { detailsStore in
			WithNavigationBar {
				destinationStore.send(.dismiss)
			} content: {
				DappDetails.View(store: detailsStore)
			}
		}
	}

	private func unknownComponents(with destinationStore: PresentationStoreOf<Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.unknownDappComponents, action: \.unknownDappComponents)) {
			InteractionReview.UnknownDappComponents.View(store: $0)
				.inNavigationStack
				.presentationDetents([.medium])
		}
	}

	private func fungibleTokenDetails(with destinationStore: PresentationStoreOf<Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.fungibleTokenDetails, action: \.fungibleTokenDetails)) {
			FungibleTokenDetails.View(store: $0)
		}
	}

	private func nonFungibleTokenDetails(with destinationStore: PresentationStoreOf<Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.nonFungibleTokenDetails, action: \.nonFungibleTokenDetails)) {
			NonFungibleTokenDetails.View(store: $0)
		}
	}

	private func lsuDetails(with destinationStore: PresentationStoreOf<Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.lsuDetails, action: \.lsuDetails)) {
			LSUDetails.View(store: $0)
		}
	}

	private func poolUnitDetails(with destinationStore: PresentationStoreOf<Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.poolUnitDetails, action: \.poolUnitDetails)) {
			PoolUnitDetails.View(store: $0)
		}
	}
}
