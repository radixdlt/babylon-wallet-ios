import FeaturePrelude

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
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { _ in
				Text("HELLO WORLD")
					.sectionHeading
			}
			.padding(.horizontal, .medium3)
			.padding(.bottom, .medium1)
		}

		struct GuaranteeView: SwiftUI.View {
			struct ViewState: Equatable {
				let token: TransactionReviewTokenView.ViewState
				let minimum: Double
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
								Text(viewState.minimum.formatted(.number))
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
