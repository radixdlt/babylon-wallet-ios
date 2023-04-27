import FeaturePrelude
import Profile
import SigningFeature

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
			message: message,
			isExpandedDappUsed: dAppsUsed?.isExpanded == true,
			showDepositsHeading: deposits != nil,
			viewControlState: viewControlState,
			showDottedLine: (withdrawals != nil || message != nil) && deposits != nil,
			rawTransaction: displayMode.rawTransaction,
			showApproveButton: transactionWithLockFee != nil
		)
	}

	private var viewControlState: ControlState {
		if transactionWithLockFee == nil {
			return .loading(.global(text: L10n.TransactionSigning.preparingTransactionLoadingText))
//		} else if isProcessingTransaction {
//			return .loading(.global(text: L10n.TransactionSigning.signingAndSubmittingTransactionLoadingText))
		} else {
			return .enabled
		}
	}
}

// MARK: - TransactionReview.View
extension TransactionReview {
	public struct ViewState: Equatable {
		let message: String?
		let isExpandedDappUsed: Bool
		let showDepositsHeading: Bool
		let viewControlState: ControlState
		let showDottedLine: Bool
		let rawTransaction: String?
		let showApproveButton: Bool
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
					.background(.app.gray5)
					.animation(.easeInOut, value: viewStore.isExpandedDappUsed)
					.navigationTitle(L10n.TransactionReview.title)
					.toolbar {
						ToolbarItem(placement: .automatic) {
							Button(asset: AssetResource.code) {
								viewStore.send(.showRawTransactionTapped)
							}
							.buttonStyle(.secondaryRectangular(isInToolbar: true))
							.brightness(viewStore.rawTransaction == nil ? 0 : -0.15)
						}
					}
					.customizeGuarantees(with: store, viewStore)
					.selectFeePayer(with: store, viewStore)
					.signing(with: store, viewStore)
					.submitting(with: store, viewStore)
					.onAppear {
						viewStore.send(.appeared)
					}
			}
		}

		@ViewBuilder
		private func coreView(with viewStore: ViewStoreOf<TransactionReview>) -> some SwiftUI.View {
			ScrollView(showsIndicators: false) {
				VStack(spacing: 0) {
					FixedSpacer(height: .medium2)

					if let rawTransaction = viewStore.rawTransaction {
						RawTransactionView(transaction: rawTransaction)
							.padding(.bottom, .medium3)
					} else {
						VStack(spacing: 0) {
							messageSection(with: viewStore.message)

							withdrawalsSection

							usingDappsSection(
								expanded: viewStore.isExpandedDappUsed,
								showDepositsHeading: viewStore.showDepositsHeading,
								showDottedLine: viewStore.showDottedLine
							)

							depositsSection

							Separator()
								.padding(.bottom, .medium1)

							proofsSection

							feeSection
						}
					}

					if viewStore.showApproveButton {
						Button(L10n.TransactionReview.approveButtonTitle, asset: AssetResource.lock) {
							viewStore.send(.approveTapped)
						}
						.buttonStyle(.primaryRectangular)
						.padding(.bottom, .medium1)
					}
				}
				.animation(.easeInOut, value: viewStore.rawTransaction)
				.padding(.horizontal, .medium3)
			}
		}

		@ViewBuilder
		private func messageSection(with message: String?) -> some SwiftUI.View {
			if let message {
				TransactionHeading(L10n.TransactionReview.messageHeading)
					.padding(.bottom, .small2)

				TransactionMessageView(message: message)
			}
		}

		@ViewBuilder
		private var withdrawalsSection: some SwiftUI.View {
			let withdrawalsStore = store.scope(state: \.withdrawals) { .child(.withdrawals($0)) }
			IfLetStore(withdrawalsStore) { childStore in
				TransactionHeading(L10n.TransactionReview.withdrawalsHeading)
					.padding(.top, .medium2)
					.padding(.bottom, .small2)

				TransactionReviewAccounts.View(store: childStore)
			}
		}

		@ViewBuilder
		private func usingDappsSection(
			expanded: Bool,
			showDepositsHeading: Bool,
			showDottedLine: Bool
		) -> some SwiftUI.View {
			VStack(alignment: .trailing, spacing: .medium2) {
				let usedDappsStore = store.scope(state: \.dAppsUsed) { .child(.dAppsUsed($0)) }
				IfLetStore(usedDappsStore) { childStore in
					TransactionReviewDappsUsed.View(store: childStore, isExpanded: expanded)
						.padding(.top, .medium2)
				} else: {
					FixedSpacer(height: .medium2)
				}

				if showDepositsHeading {
					TransactionHeading(L10n.TransactionReview.depositsHeading)
						.padding(.bottom, .small2)
				}
			}
			.background(alignment: .trailing) {
				if showDottedLine {
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
					.padding(.bottom, .medium1)
			}
		}

		@ViewBuilder
		private var proofsSection: some SwiftUI.View {
			let proofsStore = store.scope(state: \.proofs) { .child(.proofs($0)) }
			IfLetStore(proofsStore) { childStore in
				TransactionReviewProofs.View(store: childStore)

				Separator()
					.padding(.bottom, .medium1)
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

extension View {
	@MainActor
	fileprivate func customizeGuarantees(
		with store: StoreOf<TransactionReview>,
		_ viewStore: ViewStoreOf<TransactionReview>
	) -> some View {
		self.sheet(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /TransactionReview.Destinations.State.customizeGuarantees,
			action: TransactionReview.Destinations.Action.customizeGuarantees,
			content: { TransactionReviewGuarantees.View(store: $0) }
		)
	}

	@MainActor
	fileprivate func selectFeePayer(
		with store: StoreOf<TransactionReview>,
		_ viewStore: ViewStoreOf<TransactionReview>
	) -> some View {
		self.sheet(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /TransactionReview.Destinations.State.selectFeePayer,
			action: TransactionReview.Destinations.Action.selectFeePayer,
			content: { SelectFeePayer.View(store: $0) }
		)
	}

	@MainActor
	fileprivate func signing(
		with store: StoreOf<TransactionReview>,
		_ viewStore: ViewStoreOf<TransactionReview>
	) -> some View {
		self.sheet(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /TransactionReview.Destinations.State.signing,
			action: TransactionReview.Destinations.Action.signing,
			content: { Signing.View(store: $0) }
		)
	}

	@MainActor
	fileprivate func submitting(
		with store: StoreOf<TransactionReview>,
		_ viewStore: ViewStoreOf<TransactionReview>
	) -> some View {
		self.sheet(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /TransactionReview.Destinations.State.submitting,
			action: TransactionReview.Destinations.Action.submitting,
			content: { SubmitTransaction.View(store: $0) }
		)
	}
}

// MARK: - VLine
struct VLine: Shape {
	func path(in rect: CGRect) -> SwiftUI.Path {
		SwiftUI.Path { path in
			path.move(to: .init(x: rect.midX, y: rect.minY))
			path.addLine(to: .init(x: rect.midX, y: rect.maxY))
		}
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
			.foregroundColor(.app.gray1)
			.frame(
				maxWidth: .infinity,
				maxHeight: .infinity,
				alignment: .topLeading
			)
			.padding()
			.multilineTextAlignment(.leading)
	}
}

// MARK: - TransactionReviewTokenView
struct TransactionReviewTokenView: View {
	struct ViewState: Equatable {
		let name: String?
		let isXRD: Bool
		let thumbnail: URL?

		let amount: BigDecimal
		let guaranteedAmount: BigDecimal?
		let fiatAmount: BigDecimal?
	}

	let viewState: ViewState

	var body: some View {
		HStack(spacing: .small1) {
			if let thumbnail = viewState.thumbnail {
				TokenPlaceholder(size: .small) // TODO:  Actually use URL
					.padding(.vertical, .small1)
			} else {
				TokenPlaceholder(isXRD: viewState.isXRD, size: .small)
					.padding(.vertical, .small1)
			}

			if let name = viewState.name {
				Text(name)
					.textStyle(.body2HighImportance)
					.foregroundColor(.app.gray1)
			}

			Spacer(minLength: 0)

			VStack(alignment: .trailing, spacing: 0) {
				HStack(spacing: .small2) {
					if viewState.guaranteedAmount != nil {
						Text(L10n.TransactionReview.estimated)
							.textStyle(.body2HighImportance)
							.foregroundColor(.app.gray1)
					}
					Text(viewState.amount.format())
						.textStyle(.secondaryHeader)
				}
				.foregroundColor(.app.gray1)

				if let fiatAmount = viewState.fiatAmount {
					// Text(fiatAmount.formatted(.currency(code: "USD")))
					Text(fiatAmount.format())
						.textStyle(.body2HighImportance)
						.foregroundColor(.app.gray1)
						.padding(.top, .small2)
				}

				if let guaranteedAmount = viewState.guaranteedAmount {
					Text("\(L10n.TransactionReview.guaranteed) **\(guaranteedAmount.format())**")
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

// MARK: - FixedSpacer
public struct FixedSpacer: View {
	let width: CGFloat
	let height: CGFloat

	public init(width: CGFloat = 1, height: CGFloat = 1) {
		self.width = width
		self.height = height
	}

	public var body: some View {
		Rectangle()
			.fill(.clear)
			.frame(width: width, height: height)
	}
}

extension StrokeStyle {
	static let transactionReview = StrokeStyle(lineWidth: 2, dash: [5, 5])
}

extension Label where Title == Text, Icon == Image {
	public init(_ titleKey: LocalizedStringKey, asset: ImageAsset) {
		self.init {
			Text(titleKey)
		} icon: {
			Image(asset: asset)
				.renderingMode(.template)
		}
	}

	public init<S>(_ title: S, asset: ImageAsset) where S: StringProtocol {
		self.init {
			Text(title)
		} icon: {
			Image(asset: asset)
				.renderingMode(.template)
		}
	}
}

extension Button where Label == SwiftUI.Label<Text, Image> {
	public init(_ titleKey: LocalizedStringKey, asset: ImageAsset, action: @escaping () -> Void) {
		self.init(action: action) {
			SwiftUI.Label(titleKey, asset: asset)
		}
	}

	public init<S>(_ title: S, asset: ImageAsset, action: @escaping () -> Void) where S: StringProtocol {
		self.init(action: action) {
			SwiftUI.Label(title, asset: asset)
		}
	}
}

extension Button where Label == Image {
	public init(asset: ImageAsset, action: @escaping () -> Void) {
		self.init(action: action) {
			Image(asset: asset)
		}
	}
}
