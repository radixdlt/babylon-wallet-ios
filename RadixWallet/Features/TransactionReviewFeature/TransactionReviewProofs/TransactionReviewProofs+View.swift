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
				VStack(alignment: .leading, spacing: 0) {
					HStack {
						Text(L10n.TransactionReview.presentingHeading)
							.sectionHeading
							.textCase(.uppercase)

						//	FIXME: Uncomment and implement
						//	TransactionReviewInfoButton {
						//		viewStore.send(.infoTapped)
						//	}

						Spacer(minLength: 0)
					}
					.padding(.bottom, .medium2)

					ForEach(viewStore.proofs) { proof in
						VStack(spacing: 0) {
							ResourceBalanceView(proof.resourceBalance.viewState, appearance: .compact) {
								viewStore.send(.proofTapped(proof))
							}
							.padding(.bottom, .medium3)

							if proof.id == viewStore.proofs.last?.id {
								Separator()
									.padding(.bottom, .medium3)
							}
						}
					}
				}
			}
		}
	}
}
