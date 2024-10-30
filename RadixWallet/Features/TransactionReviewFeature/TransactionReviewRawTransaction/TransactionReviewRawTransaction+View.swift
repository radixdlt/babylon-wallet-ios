import ComposableArchitecture
import SwiftUI

// MARK: - TransactionReviewRawTransaction.View
extension TransactionReviewRawTransaction {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<TransactionReviewRawTransaction>

		init(store: StoreOf<TransactionReviewRawTransaction>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				NavigationStack {
					ScrollView {
						RawTransactionView(transaction: viewStore.transaction)
					}
					.radixToolbar(title: L10n.TransactionReview.rawTransactionTitle, alwaysVisible: false)
					.toolbar {
						ToolbarItem(placement: .cancellationAction) {
							CloseButton {
								viewStore.send(.closeTapped)
							}
						}
					}
				}
				.background(Color(white: 0.9))
			}
		}

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
	}
}
