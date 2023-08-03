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
			showDepositsHeading: deposits != nil,
			viewControlState: viewControlState,
			showDottedLine: (withdrawals != nil || message != .none) && deposits != nil,
			rawTransaction: displayMode.rawTransaction,
			showApproveButton: reviewedTransaction != nil,
			canApproveTX: canApproveTX,
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
		let showDepositsHeading: Bool
		let viewControlState: ControlState
		let showDottedLine: Bool
		let rawTransaction: String?
		let showApproveButton: Bool
		let canApproveTX: Bool
		let canToggleViewMode: Bool
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
						.controlState(viewStore.canApproveTX ? .enabled : .disabled)
						.buttonStyle(.primaryRectangular)
						.padding(.bottom, .medium1)
					}
				}
				.animation(.easeInOut, value: viewStore.canToggleViewMode ? viewStore.rawTransaction : nil)
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
			.customizeFees(with: destinationStore)
			.signing(with: destinationStore)
			.submitting(with: destinationStore)
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

	@MainActor
	private func submitting(with destinationStore: PresentationStoreOf<TransactionReview.Destinations>) -> some View {
		sheet(
			store: destinationStore,
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
		let thumbnail: TokenThumbnail.Content

		let amount: BigDecimal
		let guaranteedAmount: BigDecimal?
		let fiatAmount: BigDecimal?
	}

	let viewState: ViewState

	var body: some View {
		HStack(spacing: .small1) {
			TokenThumbnail(viewState.thumbnail, size: .small)
				.padding(.vertical, .small1)

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
							PlainListRow(title: title(element), showChevron: false) {
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
