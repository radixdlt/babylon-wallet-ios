import SwiftUI

extension InteractionReview.Sections.State {
	var viewState: InteractionReview.Sections.ViewState {
		.init(
			isExpandedDappsUsed: dAppsUsed?.isExpanded == true,
			isExpandedContributingToPools: contributingToPools?.isExpanded == true,
			isExpandedRedeemingFromPools: redeemingFromPools?.isExpanded == true,
			showTransferLine: withdrawals != nil && deposits != nil,
			showProofs: kind == .preAuthorization,
			showPossibleDappCalls: dAppsUsed?.showPossibleDappCalls == true,
			stakingToValidators: stakingToValidators,
			unstakingFromValidators: unstakingFromValidators,
			claimingFromValidators: claimingFromValidators,
			accountDepositSetting: accountDepositSetting,
			accountDepositExceptions: accountDepositExceptions,
		)
	}
}

// MARK: - InteractionReview.Sections.View
extension InteractionReview.Sections {
	struct ViewState: Equatable {
		let isExpandedDappsUsed: Bool
		let isExpandedContributingToPools: Bool
		let isExpandedRedeemingFromPools: Bool
		let showTransferLine: Bool
		let showProofs: Bool
		let showPossibleDappCalls: Bool

		let stakingToValidators: InteractionReview.ValidatorsState?
		let unstakingFromValidators: InteractionReview.ValidatorsState?
		let claimingFromValidators: InteractionReview.ValidatorsState?
		let accountDepositSetting: InteractionReview.DepositSettingState?
		let accountDepositExceptions: InteractionReview.DepositExceptionsState?

		var isExpandedStakingToValidators: Bool { stakingToValidators?.isExpanded == true }
		var isExpandedUnstakingFromValidators: Bool { unstakingFromValidators?.isExpanded == true }
		var isExpandedClaimingFromValidators: Bool { claimingFromValidators?.isExpanded == true }
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<InteractionReview.Sections>

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(alignment: .leading, spacing: .medium1) {
					accountDeletion
					withdrawals

					VStack(alignment: .leading, spacing: .medium1) {
						contributingToPools(viewStore.isExpandedContributingToPools)
						redeemingFromPools(viewStore.isExpandedRedeemingFromPools)

						stakingToValidators(viewStore.stakingToValidators)
						unstakingFromValidators(viewStore.unstakingFromValidators)
						claimingFromValidators(viewStore.claimingFromValidators)

						dAppsUsed(viewStore.isExpandedDappsUsed, showPossibleDappCalls: viewStore.showPossibleDappCalls)

						deposits

						if viewStore.showProofs {
							proofs
						}
					}
					.frame(maxWidth: .infinity, alignment: .leading) // necessary?
					.background(alignment: .trailing) {
						if viewStore.showTransferLine {
							Common.TransferLineView()
						}
					}

					accountDepositSetting(viewStore.accountDepositSetting)
					accountDepositExceptions(viewStore.accountDepositExceptions)
				}
				.animation(.easeInOut, value: viewStore.isExpandedDappsUsed)
				.animation(.easeInOut, value: viewStore.isExpandedContributingToPools)
				.animation(.easeInOut, value: viewStore.isExpandedRedeemingFromPools)
				.animation(.easeInOut, value: viewStore.isExpandedStakingToValidators)
				.animation(.easeInOut, value: viewStore.isExpandedUnstakingFromValidators)
				.animation(.easeInOut, value: viewStore.isExpandedClaimingFromValidators)
			}
			.destinations(with: store)
		}

		@ViewBuilder
		private var withdrawals: some SwiftUI.View {
			IfLetStore(store.scope(state: \.withdrawals, action: \.child.withdrawals)) { childStore in
				VStack(alignment: .leading, spacing: .small2) {
					Common.HeadingView.withdrawing
					Common.Accounts.View(store: childStore)
				}
			}
		}

		@ViewBuilder
		private func contributingToPools(_ isExpanded: Bool) -> some SwiftUI.View {
			IfLetStore(store.scope(state: \.contributingToPools, action: \.child.contributingToPools)) { childStore in
				VStack(alignment: .leading, spacing: .small2) {
					Common.ExpandableHeadingView(heading: .contributingToPools, isExpanded: isExpanded) {
						store.send(.view(.expandableItemToggled(.contributingToPools)))
					}
					if isExpanded {
						InteractionReviewPools.View(store: childStore)
							.transition(.opacity.combined(with: .scale(scale: 0.95)))
					}
				}
			}
		}

		@ViewBuilder
		private func redeemingFromPools(_ isExpanded: Bool) -> some SwiftUI.View {
			IfLetStore(store.scope(state: \.redeemingFromPools, action: \.child.redeemingFromPools)) { childStore in
				VStack(alignment: .leading, spacing: .small2) {
					Common.ExpandableHeadingView(heading: .redeemingFromPools, isExpanded: isExpanded) {
						store.send(.view(.expandableItemToggled(.redeemingFromPools)))
					}
					if isExpanded {
						InteractionReviewPools.View(store: childStore)
							.transition(.opacity.combined(with: .scale(scale: 0.95)))
					}
				}
			}
		}

		@ViewBuilder
		private func stakingToValidators(_ viewState: InteractionReview.ValidatorsState?) -> some SwiftUI.View {
			if let viewState {
				Common.ValidatorsView(heading: .stakingToValidators, viewState: viewState) {
					store.send(.view(.expandableItemToggled(.stakingToValidators)))
				}
			}
		}

		@ViewBuilder
		private func unstakingFromValidators(_ viewState: InteractionReview.ValidatorsState?) -> some SwiftUI.View {
			if let viewState {
				Common.ValidatorsView(heading: .unstakingFromValidators, viewState: viewState) {
					store.send(.view(.expandableItemToggled(.unstakingFromValidators)))
				}
			}
		}

		@ViewBuilder
		private func claimingFromValidators(_ viewState: InteractionReview.ValidatorsState?) -> some SwiftUI.View {
			if let viewState {
				Common.ValidatorsView(heading: .claimingFromValidators, viewState: viewState) {
					store.send(.view(.expandableItemToggled(.claimingFromValidators)))
				}
			}
		}

		@ViewBuilder
		private func accountDepositSetting(_ viewState: InteractionReview.DepositSettingState?) -> some SwiftUI.View {
			if let viewState {
				VStack(alignment: .leading, spacing: .small2) {
					Common.HeadingView.depositSetting
					Common.DepositSettingView(viewState: viewState)
				}
			}
		}

		@ViewBuilder
		private func accountDepositExceptions(_ viewState: InteractionReview.DepositExceptionsState?) -> some SwiftUI.View {
			if let viewState {
				VStack(alignment: .leading, spacing: .small2) {
					Common.HeadingView.depositExceptions
					Common.DepositExceptionsView(viewState: viewState)
				}
			}
		}

		@ViewBuilder
		private func dAppsUsed(_ isExpanded: Bool, showPossibleDappCalls: Bool) -> some SwiftUI.View {
			IfLetStore(store.scope(state: \.dAppsUsed, action: \.child.dAppsUsed)) { childStore in
				VStack(alignment: .leading, spacing: .small2) {
					Common.ExpandableHeadingView(heading: .usingDapps, isExpanded: isExpanded) {
						store.send(.view(.expandableItemToggled(.dAppsUsed)))
					}
					if isExpanded {
						if !childStore.rows.isEmpty {
							InteractionReviewDappsUsed.View(store: childStore)
								.transition(.opacity.combined(with: .scale(scale: 0.95)))
						}

						if showPossibleDappCalls {
							possibleDappCalls
								.transition(.opacity.combined(with: .scale(scale: 0.95)))
						}
					}
				}
			}
		}

		private var possibleDappCalls: some SwiftUI.View {
			HStack(spacing: .zero) {
				Image(.transactionReviewDapps)
					.renderingMode(.template)
					.resizable()
					.foregroundStyle(.app.gray3)
					.frame(.smallest)

				Text(L10n.InteractionReview.possibleDappCalls)
					.textStyle(.body2HighImportance)
					.foregroundStyle(.app.gray2)
					.padding(.leading, .small2)

				Spacer()

				InfoButton(.possibledappcalls)
			}
			.padding(.leading, .medium3)
			.padding(.vertical, .small1)
			.padding(.trailing, .medium2)
			.background(.primaryBackground)
			.clipShape(RoundedRectangle(cornerRadius: .small1))
			.cardShadow
		}

		@ViewBuilder
		private var deposits: some SwiftUI.View {
			IfLetStore(store.scope(state: \.deposits, action: \.child.deposits)) { childStore in
				VStack(alignment: .leading, spacing: .small2) {
					Common.HeadingView.depositing
					Common.Accounts.View(store: childStore)
				}
			}
		}

		@ViewBuilder
		private var proofs: some SwiftUI.View {
			IfLetStore(store.scope(state: \.proofs, action: \.child.proofs)) { childStore in
				Common.Proofs.View(store: childStore)
					.padding(.horizontal, .small3)
			}
		}

		@ViewBuilder
		private var accountDeletion: some SwiftUI.View {
			IfLetStore(store.scope(state: \.accountDeletion, action: \.child.accountDeletion)) { childStore in
				VStack(alignment: .leading, spacing: .small2) {
					Common.HeadingView.deletingAccount
					Common.Accounts.View(store: childStore)
				}
			}
		}

		@ViewBuilder
		private func shieldUpdate(_ viewState: InteractionReview.ShieldState?) -> some SwiftUI.View {
			if let viewState {
				VStack(alignment: .leading, spacing: .small2) {
					Common.HeadingView.shieldUpdate
					Common.ShieldView(viewState: viewState)
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
	}

	private func dApp(with destinationStore: PresentationStoreOf<Destination>) -> some View {
		WithPerceptionTracking {
			sheet(store: destinationStore.scope(state: \.dApp, action: \.dApp)) { detailsStore in
				WithNavigationBar {
					destinationStore.send(.dismiss)
				} content: {
					DappDetails.View(store: detailsStore)
				}
			}
		}
	}

	private func unknownComponents(with destinationStore: PresentationStoreOf<Destination>) -> some View {
		WithPerceptionTracking {
			sheet(store: destinationStore.scope(state: \.unknownDappComponents, action: \.unknownDappComponents)) {
				InteractionReview.UnknownDappComponents.View(store: $0)
					.inNavigationStack
					.presentationDetents([.medium])
			}
		}
	}

	private func fungibleTokenDetails(with destinationStore: PresentationStoreOf<Destination>) -> some View {
		WithPerceptionTracking {
			sheet(store: destinationStore.scope(state: \.fungibleTokenDetails, action: \.fungibleTokenDetails)) {
				FungibleTokenDetails.View(store: $0)
			}
		}
	}

	private func nonFungibleTokenDetails(with destinationStore: PresentationStoreOf<Destination>) -> some View {
		WithPerceptionTracking {
			sheet(store: destinationStore.scope(state: \.nonFungibleTokenDetails, action: \.nonFungibleTokenDetails)) {
				NonFungibleTokenDetails.View(store: $0)
			}
		}
	}

	private func lsuDetails(with destinationStore: PresentationStoreOf<Destination>) -> some View {
		WithPerceptionTracking {
			sheet(store: destinationStore.scope(state: \.lsuDetails, action: \.lsuDetails)) {
				LSUDetails.View(store: $0)
			}
		}
	}

	private func poolUnitDetails(with destinationStore: PresentationStoreOf<Destination>) -> some View {
		WithPerceptionTracking {
			sheet(store: destinationStore.scope(state: \.poolUnitDetails, action: \.poolUnitDetails)) {
				PoolUnitDetails.View(store: $0)
			}
		}
	}
}
