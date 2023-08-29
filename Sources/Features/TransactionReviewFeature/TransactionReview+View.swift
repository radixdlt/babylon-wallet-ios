import AssetsFeature
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
			canToggleViewMode: reviewedTransaction != nil && reviewedTransaction?.transaction != .nonConforming
		)
	}

	private var viewControlState: ControlState {
		if reviewedTransaction == nil {
			return .loading(.global(text: L10n.TransactionSigning.preparingTransaction))
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
		let hasMessageOrWithdrawals: Bool
		let hasDeposits: Bool
		let viewControlState: ControlState
		let rawTransaction: String?
		let showApprovalSlider: Bool
		let canApproveTX: Bool
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
					.navigationTitle(L10n.TransactionReview.title)
					.navigationBarInlineTitleFont(.app.secondaryHeader)
					.navigationBarHideDivider()
					.navigationBarTitleColor(.app.gray1)
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
					JaggedEdge(shadowColor: shadowColor, isTopEdge: true, padding: .medium1)

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
							ApprovalSlider(title: "Slide to Sign") { // FIXME: String - and remove old
								viewStore.send(.approveTapped)
							}
							.controlState(viewStore.approvalSliderControlState)
							.padding(.horizontal, .small3)
						}
					}
					.frame(maxWidth: .infinity)
					.padding(.vertical, .large3)
					.padding(.horizontal, .large2)
					.background {
						VStack(spacing: 0) {
							JaggedEdge(shadowColor: shadowColor, isTopEdge: false)
							Color.white
						}
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
			let proofsStore = store.scope(state: \.accountDepositSettings) { .child(.accountDepositSettings($0)) }
			IfLetStore(proofsStore) { childStore in
				AccountDepositSettings.View(store: childStore)
					.padding(.bottom, .medium1)

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
	var destination: PresentationStoreOf<TransactionReview.Destinations> {
		scope(state: \.$destination, action: { .child(.destination($0)) })
	}
}

extension View {
	@MainActor
	fileprivate func destinations(with store: StoreOf<TransactionReview>) -> some View {
		let destinationStore = store.scope(state: \.$destination, action: { .child(.destination($0)) })
		return customizeGuarantees(with: destinationStore)
			.dApp(with: destinationStore)
			.fungibleTokenDetails(with: destinationStore)
			.nonFungibleTokenDetails(with: destinationStore)
			.customizeFees(with: destinationStore)
			.signing(with: destinationStore)
	}

	@MainActor
	private func customizeGuarantees(with destinationStore: PresentationStoreOf<TransactionReview.Destinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /TransactionReview.Destinations.State.customizeGuarantees,
			action: TransactionReview.Destinations.Action.customizeGuarantees,
			content: { TransactionReviewGuarantees.View(store: $0) }
		)
	}

	@MainActor
	private func dApp(with destinationStore: PresentationStoreOf<TransactionReview.Destinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /TransactionReview.Destinations.State.dApp,
			action: TransactionReview.Destinations.Action.dApp,
			content: { SimpleDappDetails.View(store: $0) }
		)
	}

	@MainActor
	private func fungibleTokenDetails(with destinationStore: PresentationStoreOf<TransactionReview.Destinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /TransactionReview.Destinations.State.fungibleTokenDetails,
			action: TransactionReview.Destinations.Action.fungibleTokenDetails,
			content: { FungibleTokenDetails.View(store: $0) }
		)
	}

	@MainActor
	private func nonFungibleTokenDetails(with destinationStore: PresentationStoreOf<TransactionReview.Destinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /TransactionReview.Destinations.State.nonFungibleTokenDetails,
			action: TransactionReview.Destinations.Action.nonFungibleTokenDetails,
			content: { NonFungibleTokenDetails.View(store: $0) }
		)
	}

	@MainActor
	private func customizeFees(with destinationStore: PresentationStoreOf<TransactionReview.Destinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /TransactionReview.Destinations.State.customizeFees,
			action: TransactionReview.Destinations.Action.customizeFees,
			content: { CustomizeFees.View(store: $0) }
		)
	}

	@MainActor
	private func signing(with destinationStore: PresentationStoreOf<TransactionReview.Destinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /TransactionReview.Destinations.State.signing,
			action: TransactionReview.Destinations.Action.signing,
			content: { Signing.SheetView(store: $0) }
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

		let amount: BigDecimal
		let guaranteedAmount: BigDecimal?
		let fiatAmount: BigDecimal?
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

extension StrokeStyle {
	static let transactionReview = StrokeStyle(lineWidth: 2, dash: [5, 5])
}

extension Button where Label == Image {
	public init(asset: ImageAsset, action: @escaping () -> Void) {
		self.init(action: action) {
			Image(asset: asset)
		}
	}
}

// FIXME: Remove and make settings use stacks

// MARK: - SimpleDappDetails

extension SimpleDappDetails {
	@MainActor
	public struct View: SwiftUI.View {
		let store: Store

		public init(store: Store) {
			self.store = store
		}
	}

	public struct ViewState: Equatable {
		let title: String
		let description: String
		let domain: URL?
		let thumbnail: URL?
		let address: DappDefinitionAddress
		let fungibles: [State.Resources.ResourceDetails]?
		let nonFungibles: [State.Resources.ResourceDetails]?
		let associatedDapps: [State.AssociatedDapp]?
	}
}

// MARK: - Body

extension SimpleDappDetails.View {
	public var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(spacing: 0) {
					DappThumbnail(.known(viewStore.thumbnail), size: .veryLarge)
						.padding(.vertical, .large2)

					InfoBlock(store: store)

					FungiblesList(store: store)

					NonFungiblesListList(store: store)
				}
				.onAppear {
					viewStore.send(.appeared)
				}
				.navigationTitle(viewStore.title)
			}
		}
	}
}

// MARK: - Extensions

private extension SimpleDappDetails.State {
	var viewState: SimpleDappDetails.ViewState {
		.init(
			title: metadata?.name ?? L10n.DAppRequest.Metadata.unknownName,
			description: metadata?.description ?? L10n.AuthorizedDapps.DAppDetails.missingDescription,
			domain: metadata?.claimedWebsites?.first,
			thumbnail: metadata?.iconURL,
			address: dAppID,
			fungibles: resources?.fungible,
			nonFungibles: resources?.nonFungible,
			associatedDapps: associatedDapps
		)
	}
}

// MARK: Child Views

extension SimpleDappDetails.View {
	@MainActor
	struct InfoBlock: View {
		let store: StoreOf<SimpleDappDetails>

		var body: some View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(alignment: .leading, spacing: .medium2) {
					Separator()

					Text(viewStore.description)
						.textBlock
						.flushedLeft

					Separator()

					HStack(spacing: 0) {
						Text(L10n.AuthorizedDapps.DAppDetails.dAppDefinition)
							.sectionHeading

						Spacer(minLength: 0)

						AddressView(.address(.account(viewStore.address)))
							.foregroundColor(.app.gray1)
							.textStyle(.body1HighImportance)
					}

					if let domain = viewStore.domain {
						Text(L10n.AuthorizedDapps.DAppDetails.website)
							.sectionHeading
						Button(domain.absoluteString) {
							viewStore.send(.openURLTapped(domain))
						}
						.buttonStyle(.url)
					}
				}
				.padding(.horizontal, .medium1)
				.padding(.bottom, .large2)
			}
		}
	}

	@MainActor
	struct FungiblesList: View {
		let store: StoreOf<SimpleDappDetails>

		var body: some View {
			WithViewStore(store, observe: \.viewState.fungibles, send: { .view($0) }) { viewStore in
				ListWithHeading(heading: L10n.AuthorizedDapps.DAppDetails.tokens, elements: viewStore.state, title: \.name) { resource in
					TokenThumbnail(.known(resource.iconURL), size: .small)
				}
			}
		}
	}

	@MainActor
	struct NonFungiblesListList: View {
		let store: StoreOf<SimpleDappDetails>

		var body: some View {
			WithViewStore(store, observe: \.viewState.nonFungibles, send: { .view($0) }) { viewStore in
				ListWithHeading(heading: L10n.AuthorizedDapps.DAppDetails.nfts, elements: viewStore.state, title: \.name) { resource in
					NFTThumbnail(resource.iconURL, size: .small)
				}
			}
		}
	}

	@MainActor
	struct ListWithHeading<Element: Identifiable, Icon: View>: View {
		let heading: String
		let elements: [Element]?
		let title: (Element) -> String
		let icon: (Element) -> Icon

		var body: some View {
			if let elements, !elements.isEmpty {
				VStack(alignment: .leading, spacing: .medium3) {
					Text(heading)
						.sectionHeading
						.padding(.horizontal, .medium1)

					ForEach(elements) { element in
						Card {
							PlainListRow(title: title(element), accessory: nil) {
								icon(element)
							}
						}
						.padding(.horizontal, .medium3)
					}
				}
				.padding(.bottom, .medium1)
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

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
		message: .none
	)
}
#endif
