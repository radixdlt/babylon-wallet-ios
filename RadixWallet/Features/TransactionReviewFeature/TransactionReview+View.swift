import ComposableArchitecture
import SwiftUI

extension View {
	var sectionHeading: some View {
		textStyle(.body1Header)
			.foregroundColor(.app.gray2)
	}

	var message: some View {
		textStyle(.body1Regular)
			.foregroundColor(.app.gray1)
	}
}

extension TransactionReview.State {
	var viewState: TransactionReview.ViewState {
		.init(
			message: message.plaintext,
			isExpandedDappUsed: dAppsUsed?.isExpanded == true,
			isExpandedContributingToPools: contributingToPools?.isExpanded == true,
			isExpandedRedeemingFromPools: redeemingFromPools?.isExpanded == true,
			showTransferLine: withdrawals != nil && deposits != nil,
			viewControlState: viewControlState,
			rawTransaction: displayMode.rawTransaction,
			showApprovalSlider: reviewedTransaction != nil,
			canApproveTX: canApproveTX && reviewedTransaction?.feePayingValidation.wrappedValue?.isValid == true,
			sliderResetDate: sliderResetDate,
			canToggleViewMode: reviewedTransaction != nil && reviewedTransaction?.isNonConforming == false,
			viewRawTransactionButtonState: reviewedTransaction?.feePayer.isSuccess == true ? .enabled : .disabled,
			proposingDappMetadata: proposingDappMetadata,
			stakingToValidators: stakingToValidators,
			unstakingFromValidators: unstakingFromValidators,
			claimingFromValidators: claimingFromValidators,
			depositSettingSection: accountDepositSetting,
			depositExceptionsSection: accountDepositExceptions
		)
	}

	private var viewControlState: ControlState {
		if reviewedTransaction == nil {
			.loading(.global(text: L10n.TransactionSigning.preparingTransaction))
		} else {
			.enabled
		}
	}
}

// MARK: - TransactionReview.View
extension TransactionReview {
	struct ViewState: Equatable {
		let message: String?
		let isExpandedDappUsed: Bool
		let isExpandedContributingToPools: Bool
		let isExpandedRedeemingFromPools: Bool
		var isExpandedStakingToValidators: Bool { stakingToValidators?.isExpanded == true }
		var isExpandedUnstakingFromValidators: Bool { unstakingFromValidators?.isExpanded == true }
		var isExpandedClaimingFromValidators: Bool { claimingFromValidators?.isExpanded == true }

		let showTransferLine: Bool
		let viewControlState: ControlState
		let rawTransaction: String?
		let showApprovalSlider: Bool
		let canApproveTX: Bool
		let sliderResetDate: Date
		let canToggleViewMode: Bool
		let viewRawTransactionButtonState: ControlState
		let proposingDappMetadata: DappMetadata.Ledger?

		let stakingToValidators: Common.ValidatorsState?
		let unstakingFromValidators: Common.ValidatorsState?
		let claimingFromValidators: Common.ValidatorsState?
		let depositSettingSection: Common.DepositSettingState?
		let depositExceptionsSection: Common.DepositExceptionsState?

		var approvalSliderControlState: ControlState {
			// TODO: Is this the logic we want?
			canApproveTX ? viewControlState : .disabled
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		@SwiftUI.State private var showNavigationTitle: Bool = false

		private let store: StoreOf<TransactionReview>

		private let coordSpace: String = "TransactionReviewCoordSpace"
		private let navTitleID: String = "TransactionReview.title"
		private let showTitleHysteresis: CGFloat = .small3

		private let shadowColor: Color = .app.gray2.opacity(0.4)

		init(store: StoreOf<TransactionReview>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				coreView(with: viewStore)
					.controlState(viewStore.viewControlState)
					.background(.white)
					.animation(.easeInOut, value: viewStore.isExpandedDappUsed)
					.animation(.easeInOut, value: viewStore.isExpandedContributingToPools)
					.animation(.easeInOut, value: viewStore.isExpandedRedeemingFromPools)
					.animation(.easeInOut, value: viewStore.isExpandedStakingToValidators)
					.animation(.easeInOut, value: viewStore.isExpandedUnstakingFromValidators)
					.animation(.easeInOut, value: viewStore.isExpandedClaimingFromValidators)
					.toolbar {
						ToolbarItem(placement: .automatic) {
							if viewStore.canToggleViewMode {
								Button(asset: AssetResource.iconTxnBlocks) {
									viewStore.send(.showRawTransactionTapped)
								}
								.controlState(viewStore.viewRawTransactionButtonState)
								.buttonStyle(.secondaryRectangular(isInToolbar: true))
								.brightness(viewStore.rawTransaction == nil ? 0 : -0.15)
							}
						}

						ToolbarItem(placement: .principal) {
							if showNavigationTitle {
								VStack(spacing: 0) {
									Text(L10n.TransactionReview.title)
										.textStyle(.body2Header)
										.foregroundColor(.app.gray1)

									if let name = viewStore.proposingDappMetadata?.name {
										Text(L10n.TransactionReview.proposingDappSubtitle(name.rawValue))
											.textStyle(.body2Regular)
											.foregroundColor(.app.gray2)
									}
								}
							}
						}
					}
					.destinations(with: store)
					.onAppear {
						viewStore.send(.appeared)
					}
			}
		}

		@ViewBuilder
		private func coreView(with viewStore: ViewStoreOf<TransactionReview>) -> some SwiftUI.View {
			ScrollView(showsIndicators: false) {
				VStack(spacing: 0) {
					header(viewStore.proposingDappMetadata)

					if let rawTransaction = viewStore.rawTransaction {
						Common.RawTransactionView(transaction: rawTransaction) {
							viewStore.send(.copyRawTransactionTapped)
						}
					} else {
						VStack(spacing: .medium1) {
							messageSection(with: viewStore.message)

							sections
						}
						.padding(.top, .small1)
						.padding(.horizontal, .medium3)
						.padding(.bottom, .large1)
					}

					VStack(spacing: .medium1) {
						proofsSection

						feeSection

						if viewStore.showApprovalSlider {
							ApprovalSlider(
								title: L10n.TransactionReview.slideToSign,
								resetDate: viewStore.sliderResetDate
							) {
								viewStore.send(.approvalSliderSlid)
							}
							.controlState(viewStore.approvalSliderControlState)
							.padding(.horizontal, .small3)
						}
					}
					.frame(maxWidth: .infinity)
					.padding(.vertical, .large3)
					.padding(.horizontal, .large2)
					.background {
						JaggedEdge(shadowColor: shadowColor, isTopEdge: false)
					}
				}
				.background(Common.gradientBackground)
				.animation(.easeInOut, value: viewStore.canToggleViewMode ? viewStore.rawTransaction : nil)
			}
			.coordinateSpace(name: coordSpace)
			.onPreferenceChange(PositionsPreferenceKey.self) { positions in
				guard let offset = positions[navTitleID]?.maxY else {
					showNavigationTitle = true
					return
				}
				if showNavigationTitle, offset > showTitleHysteresis {
					showNavigationTitle = false
				} else if !showNavigationTitle, offset < 0 {
					showNavigationTitle = true
				}
			}
		}

		private func header(_ proposingDappMetadata: DappMetadata.Ledger?) -> some SwiftUI.View {
			Common.HeaderView(
				kind: .transaction,
				name: proposingDappMetadata?.name?.rawValue,
				thumbnail: proposingDappMetadata?.thumbnail
			)
			.measurePosition(navTitleID, coordSpace: coordSpace)
			.padding(.horizontal, .medium3)
			.padding(.bottom, .medium3)
			.background {
				JaggedEdge(shadowColor: shadowColor, isTopEdge: true)
			}
		}

		@ViewBuilder
		private func messageSection(with message: String?) -> some SwiftUI.View {
			if let message {
				VStack(alignment: .leading, spacing: .small2) {
					Common.HeadingView.message
					TransactionMessageView(message: message)
				}
			}
		}

		private var sections: some SwiftUI.View {
			let childStore = store.scope(state: \.sections, action: \.child.sections)
			return Common.Sections.View(store: childStore)
		}

		private var withdrawalsSection: some SwiftUI.View {
			IfLetStore(store.scope(state: \.withdrawals) { .child(.withdrawals($0)) }) { childStore in
				VStack(alignment: .leading, spacing: .small2) {
					Common.HeadingView.withdrawing
					Common.Accounts.View(store: childStore)
				}
			}
		}

		private func usingDappsSection(isExpanded: Bool) -> some SwiftUI.View {
			IfLetStore(store.scope(state: \.dAppsUsed) { .child(.dAppsUsed($0)) }) { childStore in
				VStack(alignment: .leading, spacing: .small2) {
					Common.ExpandableHeadingView(heading: .usingDapps, isExpanded: isExpanded) {
						store.send(.view(.expandUsingDappsTapped))
					}
					if isExpanded {
						InteractionReviewDappsUsed.View(store: childStore)
							.transition(.opacity.combined(with: .scale(scale: 0.95)))
					}
				}
			}
		}

		private func contributingToPools(isExpanded: Bool) -> some SwiftUI.View {
			IfLetStore(store.scope(state: \.contributingToPools) { .child(.contributingToPools($0)) }) { childStore in
				VStack(alignment: .leading, spacing: .small2) {
					Common.ExpandableHeadingView(heading: .contributingToPools, isExpanded: isExpanded) {
						store.send(.view(.expandContributingToPoolsTapped))
					}
					if isExpanded {
						InteractionReviewPools.View(store: childStore)
							.transition(.opacity.combined(with: .scale(scale: 0.95)))
					}
				}
			}
		}

		private func redeemingFromPools(isExpanded: Bool) -> some SwiftUI.View {
			IfLetStore(store.scope(state: \.redeemingFromPools) { .child(.redeemingFromPools($0)) }) { childStore in
				VStack(alignment: .leading, spacing: .small2) {
					Common.ExpandableHeadingView(heading: .redeemingFromPools, isExpanded: isExpanded) {
						store.send(.view(.expandRedeemingFromPoolsTapped))
					}
					if isExpanded {
						InteractionReviewPools.View(store: childStore)
							.transition(.opacity.combined(with: .scale(scale: 0.95)))
					}
				}
			}
		}

		private func stakingToValidatorsSection(_ viewState: InteractionReview.ValidatorsView.ViewState) -> some SwiftUI.View {
			Common.ValidatorsView(heading: .stakingToValidators, viewState: viewState) {
				store.send(.view(.expandStakingToValidatorsTapped))
			}
		}

		private func unstakingFromValidatorsSection(_ viewState: InteractionReview.ValidatorsView.ViewState) -> some SwiftUI.View {
			Common.ValidatorsView(heading: .unstakingFromValidators, viewState: viewState) {
				store.send(.view(.expandUnstakingFromValidatorsTapped))
			}
		}

		private func claimingFromValidatorsSection(_ viewState: InteractionReview.ValidatorsView.ViewState) -> some SwiftUI.View {
			Common.ValidatorsView(heading: .claimingFromValidators, viewState: viewState) {
				store.send(.view(.expandClaimingFromValidatorsTapped))
			}
		}

		private var depositsSection: some SwiftUI.View {
			IfLetStore(store.scope(state: \.deposits) { .child(.deposits($0)) }) { childStore in
				VStack(alignment: .leading, spacing: .small2) {
					Common.HeadingView.depositing
					Common.Accounts.View(store: childStore)
				}
			}
		}

		@ViewBuilder
		private func accountDepositSettingSection(_ viewState: Common.DepositSettingState) -> some SwiftUI.View {
			VStack(alignment: .leading, spacing: .small2) {
				Common.HeadingView.depositSetting
				Common.DepositSettingView(viewState: viewState)
			}
		}

		@ViewBuilder
		private func accountDepositExceptionsSection(_ viewState: Common.DepositExceptionsState) -> some SwiftUI.View {
			VStack(alignment: .leading, spacing: .small2) {
				Common.HeadingView.depositExceptions
				Common.DepositExceptionsView(viewState: viewState)
			}
		}

		private var proofsSection: some SwiftUI.View {
			let proofsStore = store.scope(state: \.proofs) { .child(.proofs($0)) }
			return IfLetStore(proofsStore) { childStore in
				Common.Proofs.View(store: childStore)
			}
		}

		private var feeSection: some SwiftUI.View {
			let feeStore = store.scope(state: \.networkFee) { .child(.networkFee($0)) }
			return IfLetStore(feeStore) { childStore in
				TransactionReviewNetworkFee.View(store: childStore)
			}
		}
	}
}

extension StoreOf<TransactionReview> {
	var destination: PresentationStoreOf<TransactionReview.Destination> {
		func scopeState(state: State) -> PresentationState<TransactionReview.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<TransactionReview>) -> some View {
		let destinationStore = store.destination
		return customizeGuarantees(with: destinationStore)
			.dApp(with: destinationStore)
			.fungibleTokenDetails(with: destinationStore)
			.nonFungibleTokenDetails(with: destinationStore)
			.lsuDetails(with: destinationStore)
			.poolUnitDetails(with: destinationStore)
			.customizeFees(with: destinationStore)
			.signing(with: destinationStore)
			.submitting(with: destinationStore)
			.unknownComponents(with: destinationStore)
			.rawTransactionAlert(with: destinationStore)
	}

	private func rawTransactionAlert(with destinationStore: PresentationStoreOf<TransactionReview.Destination>) -> some View {
		alert(
			store: destinationStore,
			state: /TransactionReview.Destination.State.rawTransactionAlert,
			action: TransactionReview.Destination.Action.rawTransactionAlert
		)
	}

	private func customizeGuarantees(with destinationStore: PresentationStoreOf<TransactionReview.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /TransactionReview.Destination.State.customizeGuarantees,
			action: TransactionReview.Destination.Action.customizeGuarantees,
			content: { TransactionReviewGuarantees.View(store: $0) }
		)
	}

	private func dApp(with destinationStore: PresentationStoreOf<TransactionReview.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /TransactionReview.Destination.State.dApp,
			action: TransactionReview.Destination.Action.dApp,
			content: { detailsStore in
				WithNavigationBar {
					destinationStore.send(.dismiss)
				} content: {
					DappDetails.View(store: detailsStore)
				}
			}
		)
	}

	private func unknownComponents(with destinationStore: PresentationStoreOf<TransactionReview.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /TransactionReview.Destination.State.unknownDappComponents,
			action: TransactionReview.Destination.Action.unknownDappComponents,
			content: {
				InteractionReview.UnknownDappComponents.View(store: $0)
					.inNavigationStack
					.presentationDetents([.medium])
			}
		)
	}

	private func fungibleTokenDetails(with destinationStore: PresentationStoreOf<TransactionReview.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /TransactionReview.Destination.State.fungibleTokenDetails,
			action: TransactionReview.Destination.Action.fungibleTokenDetails,
			content: { FungibleTokenDetails.View(store: $0) }
		)
	}

	private func nonFungibleTokenDetails(with destinationStore: PresentationStoreOf<TransactionReview.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /TransactionReview.Destination.State.nonFungibleTokenDetails,
			action: TransactionReview.Destination.Action.nonFungibleTokenDetails,
			content: { NonFungibleTokenDetails.View(store: $0) }
		)
	}

	private func lsuDetails(with destinationStore: PresentationStoreOf<TransactionReview.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /TransactionReview.Destination.State.lsuDetails,
			action: TransactionReview.Destination.Action.lsuDetails,
			content: { LSUDetails.View(store: $0) }
		)
	}

	private func poolUnitDetails(with destinationStore: PresentationStoreOf<TransactionReview.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /TransactionReview.Destination.State.poolUnitDetails,
			action: TransactionReview.Destination.Action.poolUnitDetails,
			content: { PoolUnitDetails.View(store: $0) }
		)
	}

	private func customizeFees(with destinationStore: PresentationStoreOf<TransactionReview.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /TransactionReview.Destination.State.customizeFees,
			action: TransactionReview.Destination.Action.customizeFees,
			content: { CustomizeFees.View(store: $0).inNavigationView }
		)
	}

	private func signing(with destinationStore: PresentationStoreOf<TransactionReview.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /TransactionReview.Destination.State.signing,
			action: TransactionReview.Destination.Action.signing,
			content: { Signing.View(store: $0) }
		)
	}

	private func submitting(with destinationStore: PresentationStoreOf<TransactionReview.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /TransactionReview.Destination.State.submitting,
			action: TransactionReview.Destination.Action.submitting,
			content: { SubmitTransaction.View(store: $0) }
		)
	}
}

// MARK: - TransactionMessageView
struct TransactionMessageView: View {
	let message: String

	var body: some View {
		Speechbubble {
			Text(message)
				.message
				.flushedLeft
				.padding(.horizontal, .medium3)
				.padding(.vertical, .small1)
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

struct TransactionReview_Previews: PreviewProvider {
	static var previews: some SwiftUI.View {
		TransactionReview.View(
			store: .init(initialState: .previewValue) {
				TransactionReview()
			}
		)
	}
}

extension TransactionReview.State {
	static let previewValue: Self = .init(
		unvalidatedManifest: .sample,
		nonce: .secureRandom(),
		signTransactionPurpose: .manifestFromDapp,
		message: .none,
		isWalletTransaction: false,
		proposingDappMetadata: nil,
		p2pRoute: .wallet
	)
}
#endif
