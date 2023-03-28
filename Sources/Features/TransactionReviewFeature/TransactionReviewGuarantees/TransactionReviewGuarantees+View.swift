import FeaturePrelude

// MARK: - TransactionReviewGuarantees.View
extension TransactionReviewGuarantees {
	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<TransactionReviewGuarantees>

		public init(store: StoreOf<TransactionReviewGuarantees>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store.stateless, send: { .view($0) }) { viewStore in
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

							ForEachStore(store.scope(state: \.guarantees) {},
							             content: { TransactionReviewGuarantee.View })

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
	}
}

extension TransactionReviewTokenView.ViewState {
	init(amount: BigDecimal, metadata: TransactionReview.ResourceMetadata) {
		self.init(name: metadata.name,
		          thumbnail: metadata.thumbnail,
		          amount: amount,
		          guaranteedAmount: metadata.guarantee?.amount,
		          dollarAmount: metadata.dollarAmount)
	}
}

extension TransactionReviewGuarantees.State {
	var viewState: TransactionReviewGuarantees.ViewState {
		let guarantees = transfers.map { transfer -> TransactionReviewGuarantees.View.GuaranteeView.ViewState in
			.init(id: transfer.id,
			      token: .init(amount: transfer.transfer.action.amount,
			                   metadata: transfer.transfer.metadata),
			      minimumPercentage: 100,
			      accountIfVisible: transfer.account)
		}

		return .init(guarantees: guarantees)
	}
}

extension TransactionReviewGuarantee {
	public struct ViewState: Identifiable, Equatable {
		public let id: AccountAction
		let token: TransactionReviewTokenView.ViewState
		let minimumPercentage: Double
		let accountIfVisible: TransactionReview.Account?
	}

	public struct View: SwiftUI.View {
		public let store: StoreOf<TransactionReviewGuarantee>

		public init(store: StoreOf<TransactionReviewGuarantee>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			Card {
				VStack(spacing: 0) {
					WithViewStore(store, observe: <#T##(State) -> Equatable#>, send: <#T##(ViewAction) -> Action#>, content: <#T##(ViewStore<Equatable, ViewAction>) -> View#>)
					//						TransactionReviewAccount.View(store: <#T##StoreOf<TransactionReviewAccount>#>)

					TransactionReviewTokenView(viewState: viewState.token)

					Rectangle()
						.stroke(.pink)
						.padding(.medium3)
//						.overlay {
//							Button(action: increaseAction) {
//								Image(systemName: "minus.circle")
//							}
//							Text(viewState.minimumPercentage.formatted(.number))
//							Button(action: increaseAction) {
//								Image(systemName: "plus.circle")
//							}
//						}
				}
			}
		}
	}
}
