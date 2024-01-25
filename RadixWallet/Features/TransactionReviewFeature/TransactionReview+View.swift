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
			message: {
				// TODO: handle the rest of types
				if case let .plainText(value) = message,
				   case let .str(str) = value.message
				{
					return str
				}
				return nil
			}(),
			isExpandedDappUsed: dAppsUsed?.isExpanded == true,
			isExpandedContributingToPools: contributingToPools?.isExpanded == true,
			isExpandedRedeemingFromPools: redeemingFromPools?.isExpanded == true,
			showTransferLine: withdrawals != nil && deposits != nil,
			viewControlState: viewControlState,
			rawTransaction: displayMode.rawTransaction,
			showApprovalSlider: reviewedTransaction != nil,
			canApproveTX: canApproveTX && reviewedTransaction?.feePayingValidation.wrappedValue == .valid,
			sliderResetDate: sliderResetDate,
			canToggleViewMode: reviewedTransaction != nil && reviewedTransaction?.isNonConforming == false,
			viewRawTransactionButtonState: reviewedTransaction?.feePayer.isSuccess == true ? .enabled : .disabled,
			proposingDappMetadata: proposingDappMetadata,
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
	public struct ViewState: Equatable {
		let message: String?
		let isExpandedDappUsed: Bool
		let isExpandedContributingToPools: Bool
		let isExpandedRedeemingFromPools: Bool

		let showTransferLine: Bool
		let viewControlState: ControlState
		let rawTransaction: String?
		let showApprovalSlider: Bool
		let canApproveTX: Bool
		let sliderResetDate: Date
		let canToggleViewMode: Bool
		let viewRawTransactionButtonState: ControlState
		let proposingDappMetadata: DappMetadata.Ledger?

		let depositSettingSection: DepositSettingState?
		let depositExceptionsSection: DepositExceptionsState?

		var approvalSliderControlState: ControlState {
			// TODO: Is this the logic we want?
			canApproveTX ? viewControlState : .disabled
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<TransactionReview>

		public init(store: StoreOf<TransactionReview>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				coreView(with: viewStore)
					.controlState(viewStore.viewControlState)
					.background(.white)
					.animation(.easeInOut, value: viewStore.isExpandedDappUsed)
					.animation(.easeInOut, value: viewStore.isExpandedContributingToPools)
					.animation(.easeInOut, value: viewStore.isExpandedRedeemingFromPools)
					.toolbar {
						ToolbarItem(placement: .automatic) {
							if viewStore.canToggleViewMode {
								Button(asset: AssetResource.code) {
									viewStore.send(.showRawTransactionTapped)
								}
								.controlState(viewStore.viewRawTransactionButtonState)
								.buttonStyle(.secondaryRectangular(isInToolbar: true))
								.brightness(viewStore.rawTransaction == nil ? 0 : -0.15)
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
						.padding(.horizontal, .medium3)
						.padding(.bottom, .medium3)
						.background {
							JaggedEdge(shadowColor: shadowColor, isTopEdge: true)
						}

					if let rawTransaction = viewStore.rawTransaction {
						RawTransactionView(transaction: rawTransaction)
					} else {
						VStack(spacing: .medium1) {
							messageSection(with: viewStore.message)

							withdrawalsSection

							VStack(spacing: .medium1) {
								contributingToPools(isExpanded: viewStore.isExpandedContributingToPools)

								redeemingFromPools(isExpanded: viewStore.isExpandedRedeemingFromPools)

								usingDappsSection(isExpanded: viewStore.isExpandedDappUsed)

								depositsSection
							}
							.background(alignment: .trailing) {
								if viewStore.showTransferLine {
									VLine()
										.stroke(.app.gray3, style: .transactionReview)
										.frame(width: 1)
										.padding(.trailing, .huge3)
										.padding(.top, -.medium1)
								}
							}

							accountDepositSettingSection(viewStore.depositSettingSection)

							accountDepositExceptionsSection(viewStore.depositExceptionsSection)
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
				.background(.app.gray5.gradient.shadow(.inner(color: shadowColor, radius: 15)))
				.animation(.easeInOut, value: viewStore.canToggleViewMode ? viewStore.rawTransaction : nil)
			}
		}

		private let shadowColor: Color = .app.gray2.opacity(0.4)

		private func header(_ proposingDappMetadata: DappMetadata.Ledger?) -> some SwiftUI.View {
			VStack(alignment: .leading, spacing: .small3) {
				HStack(spacing: .zero) {
					Text(L10n.TransactionReview.title)
						.textStyle(.sheetTitle)
						.lineLimit(2)
						.multilineTextAlignment(.leading)
						.foregroundColor(.app.gray1)

					Spacer(minLength: 0)

					if let thumbnail = proposingDappMetadata?.thumbnail {
						DappThumbnail(.known(thumbnail), size: .medium)
							.padding(.leading, .small2)
					} else {
						Spacer(minLength: .small2 + HitTargetSize.medium.rawValue)
					}
				}

				if let name = proposingDappMetadata?.name {
					Text(L10n.TransactionReview.proposingDappSubtitle(name.rawValue))
						.textStyle(.body2HighImportance)
						.foregroundColor(.app.gray1)
				}
			}
		}

		@ViewBuilder
		private func messageSection(with message: String?) -> some SwiftUI.View {
			if let message {
				VStack(alignment: .leading, spacing: .small2) {
					TransactionHeading.message
					TransactionMessageView(message: message)
				}
			}
		}

		private var withdrawalsSection: some SwiftUI.View {
			IfLetStore(store.scope(state: \.withdrawals) { .child(.withdrawals($0)) }) { childStore in
				VStack(alignment: .leading, spacing: .small2) {
					TransactionHeading.withdrawing
					TransactionReviewAccounts.View(store: childStore)
				}
			}
		}

		private func usingDappsSection(isExpanded: Bool) -> some SwiftUI.View {
			IfLetStore(store.scope(state: \.dAppsUsed) { .child(.dAppsUsed($0)) }) { childStore in
				VStack(alignment: .leading, spacing: .small2) {
					ExpandableTransactionHeading(heading: .usingDapps, isExpanded: isExpanded) {
						store.send(.view(.expandRedeemingFromPoolsTapped))
					}
					if isExpanded {
						TransactionReviewDappsUsed.View(store: childStore)
							.transition(.opacity.combined(with: .scale(scale: 0.95)))
					}
				}
			}
		}

		private func contributingToPools(isExpanded: Bool) -> some SwiftUI.View {
			IfLetStore(store.scope(state: \.contributingToPools) { .child(.contributingToPools($0)) }) { childStore in
				VStack(alignment: .leading, spacing: .small2) {
					ExpandableTransactionHeading(heading: .contributingToPools, isExpanded: isExpanded) {
						store.send(.view(.expandContributingToPoolsTapped))
					}
					if isExpanded {
						TransactionReviewPools.View(store: childStore)
							.transition(.opacity.combined(with: .scale(scale: 0.95)))
					}
				}
			}
		}

		private func redeemingFromPools(isExpanded: Bool) -> some SwiftUI.View {
			IfLetStore(store.scope(state: \.redeemingFromPools) { .child(.redeemingFromPools($0)) }) { childStore in
				VStack(alignment: .leading, spacing: .small2) {
					ExpandableTransactionHeading(heading: .redeemingFromPools, isExpanded: isExpanded) {
						store.send(.view(.expandRedeemingFromPoolsTapped))
					}
					if isExpanded {
						TransactionReviewPools.View(store: childStore)
							.transition(.opacity.combined(with: .scale(scale: 0.95)))
					}
				}
			}
		}

		private var depositsSection: some SwiftUI.View {
			IfLetStore(store.scope(state: \.deposits) { .child(.deposits($0)) }) { childStore in
				VStack(alignment: .leading, spacing: .small2) {
					TransactionHeading.depositing
					TransactionReviewAccounts.View(store: childStore)
				}
			}
		}

		@ViewBuilder
		private func accountDepositSettingSection(_ viewState: DepositSettingState?) -> some SwiftUI.View {
			if let viewState {
				VStack(alignment: .leading, spacing: .small2) {
					TransactionHeading.depositSetting
					DepositSettingView(viewState: viewState)
				}
			}
		}

		@ViewBuilder
		private func accountDepositExceptionsSection(_ viewState: DepositExceptionsState?) -> some SwiftUI.View {
			if let viewState {
				VStack(alignment: .leading, spacing: .small2) {
					TransactionHeading.depositExceptions
					DepositExceptionsView(viewState: viewState)
				}
			}
		}

		private var proofsSection: some SwiftUI.View {
			let proofsStore = store.scope(state: \.proofs) { .child(.proofs($0)) }
			return IfLetStore(proofsStore) { childStore in
				TransactionReviewProofs.View(store: childStore)
					.padding(.bottom, .medium1)
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
			.poolUnitDetails(with: destinationStore)
			.customizeFees(with: destinationStore)
			.signing(with: destinationStore)
			.submitting(with: destinationStore)
			.unknownComponents(with: destinationStore)
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
				UnknownDappComponents.View(store: $0)
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
			content: { store in NavigationView { CustomizeFees.View(store: store) } }
		)
	}

	private func signing(with destinationStore: PresentationStoreOf<TransactionReview.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /TransactionReview.Destination.State.signing,
			action: TransactionReview.Destination.Action.signing,
			content: { Signing.SheetView(store: $0) }
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

// MARK: - ExpandableTransactionHeading
struct ExpandableTransactionHeading: View {
	let heading: TransactionHeading
	let isExpanded: Bool
	let action: () -> Void

	var body: some SwiftUI.View {
		Button(action: action) {
			HStack(spacing: .small3) {
				heading

				Image(asset: isExpanded ? AssetResource.chevronUp : AssetResource.chevronDown)
					.renderingMode(.original)

				Spacer(minLength: 0)
			}
		}
	}
}

// MARK: - TransactionHeading
struct TransactionHeading: View {
	let heading: String
	let icon: ImageAsset

	init(_ heading: String, icon: ImageAsset) {
		self.heading = heading
		self.icon = icon
	}

	var body: some View {
		HStack(spacing: .small2) {
			Image(asset: icon)
				.padding(.small3)
				.overlay {
					Circle()
						.stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
						.foregroundColor(.app.gray3)
				}
			Text(heading)
				.sectionHeading
				.textCase(.uppercase)
		}
	}

	static let message = TransactionHeading(
		L10n.TransactionReview.messageHeading,
		icon: AssetResource.transactionReviewMessage
	)

	static let withdrawing = TransactionHeading(
		L10n.TransactionReview.withdrawalsHeading,
		icon: AssetResource.transactionReviewWithdrawing
	)

	static let depositing = TransactionHeading(
		L10n.TransactionReview.depositsHeading,
		icon: AssetResource.transactionReviewDepositing
	)

	static let usingDapps = TransactionHeading(
		L10n.TransactionReview.usingDappsHeading,
		icon: AssetResource.transactionReviewDapps
	)

	static let contributingToPools = TransactionHeading(
		L10n.TransactionReview.poolContributionHeading,
		icon: AssetResource.transactionReviewPools
	)

	static let redeemingFromPools = TransactionHeading(
		L10n.TransactionReview.poolRedemptionHeading,
		icon: AssetResource.transactionReviewPools
	)

	static let depositSetting = TransactionHeading(
		L10n.TransactionReview.thirdPartyDepositSettingHeading,
		icon: AssetResource.transactionReviewDepositSetting
	)

	static let depositExceptions = TransactionHeading(
		L10n.TransactionReview.thirdPartyDepositExceptionsHeading,
		icon: AssetResource.transactionReviewDepositSetting
	)
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

// MARK: - RawTransactionView
struct RawTransactionView: SwiftUI.View {
	let transaction: String

	var body: some SwiftUI.View {
		Text(transaction)
			.textStyle(.monospace)
			.multilineTextAlignment(.leading)
			.foregroundColor(.app.gray1)
			.frame(
				maxWidth: .infinity,
				maxHeight: .infinity,
				alignment: .topLeading
			)
			.padding()
	}
}

// MARK: - TransactionReviewTokenView
struct TransactionReviewTokenView: View {
	struct ViewState: Equatable {
		let name: String?
		let thumbnail: TokenThumbnail.Content

		let amount: RETDecimal
		let guaranteedAmount: RETDecimal?
		let fiatAmount: RETDecimal?
	}

	let viewState: ViewState
	let onTap: () -> Void
	let disabled: Bool

	init(viewState: ViewState, onTap: (() -> Void)? = nil) {
		self.viewState = viewState
		self.onTap = onTap ?? {}
		self.disabled = onTap == nil
	}

	var body: some View {
		HStack(spacing: .small1) {
			Button(action: onTap) {
				TokenThumbnail(viewState.thumbnail, size: .small)
					.padding(.vertical, .small1)

				if let name = viewState.name {
					Text(name)
						.textStyle(.body2HighImportance)
						.foregroundColor(.app.gray1)
				}
			}
			.disabled(disabled)

			Spacer(minLength: 0)

			VStack(alignment: .trailing, spacing: 0) {
				if viewState.guaranteedAmount != nil {
					Text(L10n.TransactionReview.estimated)
						.textStyle(.body2HighImportance)
						.foregroundColor(.app.gray1)
				}
				Text(viewState.amount.formatted())
					.textStyle(.secondaryHeader)
					.foregroundColor(.app.gray1)

				if let fiatAmount = viewState.fiatAmount {
					// Text(fiatAmount.formatted(.currency(code: "USD")))
					Text(fiatAmount.formatted())
						.textStyle(.body2HighImportance)
						.foregroundColor(.app.gray1)
						.padding(.top, .small2)
				}

				if let guaranteedAmount = viewState.guaranteedAmount {
					Text("\(L10n.TransactionReview.guaranteed) **\(guaranteedAmount.formatted())**")
						.textStyle(.body2HighImportance)
						.foregroundColor(.app.gray2)
						.padding(.top, .small1)
				}
			}
			.padding(.vertical, .medium3)
		}
		.padding(.horizontal, .medium3)
	}
}

// MARK: - TransactionReviewInfoButton
public struct TransactionReviewInfoButton: View {
	private let action: () -> Void

	public init(action: @escaping () -> Void) {
		self.action = action
	}

	public var body: some SwiftUI.View {
		Button(action: action) {
			Image(asset: AssetResource.info)
				.renderingMode(.template)
				.foregroundColor(.app.gray3)
		}
	}
}

extension StrokeStyle {
	static let transactionReview = StrokeStyle(lineWidth: 2, dash: [5, 5])
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
	public static let previewValue: Self = .init(
		rawTransactionManifest: try! .init(manifest: .previewValue),
		nonce: .zero,
		signTransactionPurpose: .manifestFromDapp,
		message: .none,
		isWalletTransaction: false,
		proposingDappMetadata: nil
	)
}
#endif
