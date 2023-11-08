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
			hasMessageOrWithdrawals: message != .none || withdrawals != nil,
			hasDeposits: deposits != nil,
			viewControlState: viewControlState,
			rawTransaction: displayMode.rawTransaction,
			showApprovalSlider: reviewedTransaction != nil,
			canApproveTX: canApproveTX && reviewedTransaction?.feePayingValidation == .valid,
			sliderResetDate: sliderResetDate,
			canToggleViewMode: reviewedTransaction != nil && reviewedTransaction?.transaction != .nonConforming
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
		let hasMessageOrWithdrawals: Bool
		let hasDeposits: Bool
		let viewControlState: ControlState
		let rawTransaction: String?
		let showApprovalSlider: Bool
		let canApproveTX: Bool
		let sliderResetDate: Date
		let canToggleViewMode: Bool

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
					.toolbar {
						ToolbarItem(placement: .automatic) {
							if viewStore.canToggleViewMode {
								Button(asset: AssetResource.code) {
									viewStore.send(.showRawTransactionTapped)
								}
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
					Text(L10n.TransactionReview.title)
						.textStyle(.sheetTitle)
						.lineLimit(2)
						.multilineTextAlignment(.leading)
						.foregroundColor(.app.gray1)
						.flushedLeft
						.padding(.horizontal, .medium3)
						.padding(.bottom, .medium3)
						.background {
							JaggedEdge(shadowColor: shadowColor, isTopEdge: true)
						}

					if let rawTransaction = viewStore.rawTransaction {
						RawTransactionView(transaction: rawTransaction)
					} else {
						VStack(spacing: 0) {
							VStack(spacing: .medium2) {
								messageSection(with: viewStore.message)

								withdrawalsSection
							}

							usingDappsSection(for: viewStore)

							depositsSection

							accountDepositSettingsSection
						}
						.padding(.top, .medium1)
						.padding(.horizontal, .medium3)
						.padding(.bottom, .large2)
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

		@ViewBuilder
		private func messageSection(with message: String?) -> some SwiftUI.View {
			if let message {
				VStack(spacing: .small2) {
					TransactionHeading(L10n.TransactionReview.messageHeading)

					TransactionMessageView(message: message)
				}
			}
		}

		@ViewBuilder
		private var withdrawalsSection: some SwiftUI.View {
			let withdrawalsStore = store.scope(state: \.withdrawals) { .child(.withdrawals($0)) }
			IfLetStore(withdrawalsStore) { childStore in
				VStack(spacing: .small2) {
					TransactionHeading(L10n.TransactionReview.withdrawalsHeading)

					TransactionReviewAccounts.View(store: childStore)
				}
			}
		}

		@ViewBuilder
		private func usingDappsSection(for viewStore: ViewStoreOf<TransactionReview>) -> some SwiftUI.View {
			VStack(alignment: .trailing, spacing: 0) {
				let usedDappsStore = store.scope(state: \.dAppsUsed) { .child(.dAppsUsed($0)) }
				IfLetStore(usedDappsStore) { childStore in
					TransactionReviewDappsUsed.View(store: childStore, isExpanded: viewStore.isExpandedDappUsed)
						.padding(.top, viewStore.hasMessageOrWithdrawals ? .medium2 : 0)
						.padding(.bottom, viewStore.hasDeposits ? .medium2 : 0)
				} else: {
					if viewStore.hasMessageOrWithdrawals, viewStore.hasDeposits {
						FixedSpacer(height: .medium2)
					}
				}

				if viewStore.hasDeposits {
					TransactionHeading(L10n.TransactionReview.depositsHeading)
						.padding(.bottom, .small2)
				}
			}
			.frame(maxWidth: .infinity, alignment: .trailing)
			.background(alignment: .trailing) {
				if viewStore.hasMessageOrWithdrawals, viewStore.hasDeposits {
					VLine()
						.stroke(.app.gray3, style: .transactionReview)
						.frame(width: 1)
						.padding(.trailing, SpeechbubbleShape.triangleInset)
				}
			}
		}

		@ViewBuilder
		private var depositsSection: some SwiftUI.View {
			let depositsStore = store.scope(state: \.deposits) { .child(.deposits($0)) }
			IfLetStore(depositsStore) { childStore in
				TransactionReviewAccounts.View(store: childStore)
			}
		}

		@ViewBuilder
		private var proofsSection: some SwiftUI.View {
			let proofsStore = store.scope(state: \.proofs) { .child(.proofs($0)) }
			IfLetStore(proofsStore) { childStore in
				TransactionReviewProofs.View(store: childStore)
					.padding(.bottom, .medium1)

				Separator()
					.padding(.horizontal, -.small3)
			}
		}

		@ViewBuilder
		private var accountDepositSettingsSection: some SwiftUI.View {
			let accountDepositSettingsStore = store.scope(state: \.accountDepositSettings) { .child(.accountDepositSettings($0)) }
			IfLetStore(accountDepositSettingsStore) { childStore in
				VStack(spacing: .small2) {
					TransactionHeading("Account Deposit Settings")
					AccountDepositSettings.View(store: childStore)
						.padding(.bottom, .medium1)
				}

				Separator()
					.padding(.horizontal, -.small3)
			}
		}

		@ViewBuilder
		private var feeSection: some SwiftUI.View {
			let feeStore = store.scope(state: \.networkFee) { .child(.networkFee($0)) }
			IfLetStore(feeStore) { childStore in
				TransactionReviewNetworkFee.View(store: childStore)
			}
		}
	}
}

extension StoreOf<TransactionReview> {
	var destination: PresentationStoreOf<TransactionReview.Destination> {
		scope(state: \.$destination) { .child(.destination($0)) }
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
			.customizeFees(with: destinationStore)
			.signing(with: destinationStore)
			.submitting(with: destinationStore)
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

// MARK: - TransactionHeading
struct TransactionHeading: View {
	let heading: String

	init(_ heading: String) {
		self.heading = heading
	}

	var body: some View {
		Text(heading)
			.sectionHeading
			.textCase(.uppercase)
			.flushedLeft(padding: .medium3)
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
		transactionManifest: .previewValue,
		nonce: .zero,
		signTransactionPurpose: .manifestFromDapp,
		message: .none,
		isWalletTransaction: false
	)
}
#endif
