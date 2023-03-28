import FeaturePrelude

// MARK: - FungibleTransfer__
public struct FungibleTransfer__: Identifiable, Sendable, Hashable {
	public var id: AccountAction { transfer.id }
	public let account: TransactionReview.Account
	public let transfer: TransactionReview.Transfer
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
			.init(token: <#T##TransactionReviewTokenView.ViewState#>,
			      minimumPercentage: 100,
			      accountIfVisible: transfer.account)
		}

		return .init(guarantees: [])
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
			struct ViewState: Equatable {
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
