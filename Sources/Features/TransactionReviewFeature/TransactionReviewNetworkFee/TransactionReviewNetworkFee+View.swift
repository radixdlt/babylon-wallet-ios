import FeaturePrelude

// MARK: - TransactionReviewDappsUsed.View
extension TransactionReviewNetworkFee {
	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<TransactionReviewNetworkFee>

		public init(store: StoreOf<TransactionReviewNetworkFee>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in

				VStack(alignment: .leading, spacing: .small2) {
					HStack {
						Text(L10n.TransactionReview.NetworkFee.heading)
							.sectionHeading
							.textCase(.uppercase)

						//	FIXME: Uncomment and implement
						//	TransactionReviewInfoButton {
						//	viewStore.send(.infoTapped)
						//	}

						Spacer(minLength: 0)

						Text(viewStore.feePayerSelection.transactionFee.totalFee.displayedTotalFee) // TODO:  Revisit
							.textStyle(.body1HighImportance)
							.foregroundColor(.app.gray1)
					}

					if viewStore.feePayerSelection.transactionFee.totalFee.lockFee > .zero {
						if let feePayer = viewStore.feePayerSelection.selected {
							if feePayer.xrdBalance < viewStore.feePayerSelection.transactionFee.totalFee.lockFee {
								WarningErrorView(text: "Insufficient balance to pay the transaction fee", type: .error)
							}
						} else {
							WarningErrorView(text: "Please select a fee payer for the transaction fee", type: .warning)
						}
					}

					Button(L10n.TransactionReview.NetworkFee.customizeButtonTitle) {
						viewStore.send(.customizeTapped)
					}
					.textStyle(.body1StandaloneLink)
					.foregroundColor(.app.blue2)
				}
			}
			.padding(.horizontal, .medium3)
			.padding(.bottom, .medium1)
		}
	}
}
