import ComposableArchitecture
import SwiftUI

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

						Text(viewStore.reviewedTransaction.transactionFee.totalFee.displayedTotalFee)
							.textStyle(.body1HighImportance)
							.foregroundColor(.app.gray1)
					}

					loadable(viewStore.reviewedTransaction.feePayingValidation) { validation in
						if case .needsFeePayer = validation {
							WarningErrorView(text: L10n.TransactionReview.feePayerRequiredMessage, type: .warning)
						} else if case .insufficientBalance = validation {
							WarningErrorView(text: L10n.TransactionReview.insufficientBalance, type: .error)
						}

						Button(L10n.TransactionReview.NetworkFee.customizeButtonTitle) {
							viewStore.send(.customizeTapped)
						}
						.textStyle(.body1StandaloneLink)
						.foregroundColor(.app.blue2)
					}
				}
			}
		}
	}
}
