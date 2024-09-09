import ComposableArchitecture
import SwiftUI

// MARK: - TransactionReviewProofs.View
extension TransactionReviewProofs {
	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<TransactionReviewProofs>

		public init(store: StoreOf<TransactionReviewProofs>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				VStack(alignment: .leading, spacing: .medium2) {
					HStack {
						Text(L10n.TransactionReview.presentingHeading)
							.sectionHeading
							.textCase(.uppercase)

						InfoButton(.badges)

						Spacer(minLength: 0)
					}

					ForEach(viewStore.proofs) { proof in
						ResourceBalanceView(proof.resourceBalance.viewState, appearance: .compact) {
							viewStore.send(.proofTapped(proof))
						}
					}
					Separator()
				}
			}
		}
	}
}
