import FeaturePrelude

// MARK: - TransactionReviewPresenting.View
extension TransactionReviewGuarantees {
	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<TransactionReviewGuarantees>

		public init(store: StoreOf<TransactionReviewGuarantees>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { _ in
				Text("HELLO WORLD")
					.sectionHeading
			}
			.padding(.horizontal, .medium3)
			.padding(.bottom, .medium1)
		}

		struct GuaranteeView: SwiftUI.View {
			let name: String?
			let thumbnail: URL?

			let amount: BigDecimal
			let guaranteedAmount: BigDecimal?
			let dollarAmount: BigDecimal?

			let action: (Change) -> Void

			enum Change {
				case increase, decrease
			}

			public var body: some SwiftUI.View {
				VStack(spacing: .medium2) {
					TransactionReviewTokenView(name: name,
					                           thumbnail: thumbnail,
					                           amount: amount,
					                           guaranteedAmount: guaranteedAmount,
					                           dollarAmount: dollarAmount)
				}
			}
		}
	}
}
