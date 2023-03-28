import FeaturePrelude

// MARK: - FungibleTransfer__
public struct FungibleTransfer__: Identifiable, Sendable, Hashable {
	public var id: AccountAction { transfer.id }
	public let account: TransactionReview.Account
	public let transfer: TransactionReview.Transfer
}

// MARK: - Transfer__
public struct Transfer__: Sendable, Identifiable, Hashable {
	public var id: AccountAction { action }

	public let action: AccountAction
	public var metadata: ResourceMetadata__
}

// MARK: - ResourceMetadata__
public struct ResourceMetadata__: Sendable, Hashable {
	public let name: String?
	public let thumbnail: URL?
	public var type: ResourceType__?
	public var guaranteedAmount: BigDecimal?
	public var dollarAmount: BigDecimal?
}

// MARK: - ResourceType__
public enum ResourceType__: Sendable, Hashable {
	case fungible
	case nonFungible
}

/*

  to:

 let token: TransactionReviewTokenView.ViewState
 let minimumPercentage: Double
 let accountIfVisible: TransactionReview.Account?

  token:
 struct ViewState: Equatable {
     let name: String?
     let thumbnail: URL?

     let amount: BigDecimal
     let guaranteedAmount: BigDecimal?
     let dollarAmount: BigDecimal?
 }
 */

extension TransactionReviewGuarantees.State {
	var viewState: TransactionReviewGuarantees.ViewState {
		let guarantees = transfers.map { transfer -> TransactionReviewGuarantees.View.GuaranteeView.ViewState in
			let metadata = transfer.transfer.metadata
			return .init(id: transfer.id,
			             token: .init(name: metadata.name,
			                          thumbnail: metadata.thumbnail,
			                          amount: transfer.transfer.action.amount,
			                          guaranteedAmount: metadata.guaranteedAmount,
			                          dollarAmount: metadata.dollarAmount),
			             minimumPercentage: 100,
			             accountIfVisible: transfer.account)
		}

		return .init(guarantees: guarantees)
	}
}

// MARK: - TransactionReviewPresenting.View
extension TransactionReviewGuarantees {
	public struct ViewState: Equatable {
		let guarantees: [View.GuaranteeView.ViewState]
	}

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<TransactionReviewGuarantees>

		public init(store: StoreOf<TransactionReviewGuarantees>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				NavigationStack {
					ScrollView(showsIndicators: false) {
						VStack(spacing: 0) {
							FixedSpacer(height: .medium3)

							Button(L10n.TransactionReview.Guarantees.infoButtonText, asset: AssetResource.info) {
								viewStore.send(.infoTapped)
							}
							.textStyle(.body1Header)
							.foregroundColor(.app.blue2)
							.padding(.horizontal, .large2)
							.padding(.bottom, .medium1)

							Text(L10n.TransactionReview.Guarantees.headerText)
								.textStyle(.body1Regular)
								.multilineTextAlignment(.center)
								.foregroundColor(.app.gray1)
								.padding(.horizontal, .large2)
								.padding(.bottom, .medium1)

							ForEach(viewStore.guarantees) { viewState in
								GuaranteeView(viewState: viewState) {} decreaseAction: {}
							}
						}
					}
					.padding(.bottom, .medium1)
					.navigationTitle(L10n.TransactionReview.Guarantees.title)
					.toolbar {
						ToolbarItem(placement: .cancellationAction) {
							CloseButton {
								viewStore.send(.closeTapped)
							}
						}
					}
				}
			}
		}

		struct GuaranteeView: SwiftUI.View {
			struct ViewState: Identifiable, Equatable {
				let id: AccountAction
				let token: TransactionReviewTokenView.ViewState
				let minimumPercentage: Double
				let accountIfVisible: TransactionReview.Account?
			}

			let viewState: ViewState
			let increaseAction: () -> Void
			let decreaseAction: () -> Void

			public var body: some SwiftUI.View {
				Card {
					VStack(spacing: 0) {
						TransactionReviewTokenView(viewState: viewState.token)

						Rectangle()
							.stroke(.pink)
							.padding(.medium3)
							.overlay {
								Button(action: increaseAction) {
									Image(systemName: "minus.circle")
								}
								Text(viewState.minimumPercentage.formatted(.number))
								Button(action: increaseAction) {
									Image(systemName: "plus.circle")
								}
							}
					}
				}
			}
		}
	}
}
