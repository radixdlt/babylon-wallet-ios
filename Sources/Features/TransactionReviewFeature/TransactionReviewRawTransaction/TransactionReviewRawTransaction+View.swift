import FeaturePrelude

// MARK: - TransactionReviewRawTransaction.View
extension TransactionReviewRawTransaction {
	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<TransactionReviewRawTransaction>

		public init(store: StoreOf<TransactionReviewRawTransaction>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				NavigationStack {
					ScrollView {
						RawTransactionView(transaction: viewStore.transaction)
					}
					.navigationTitle(L10n.TransactionReview.rawTransactionTitle)
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
					.textStyle(.monospaced)
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
