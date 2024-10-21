import ComposableArchitecture
import SwiftUI

// MARK: - InteractionReviewProofs.View
extension InteractionReviewCommon.Proofs {
	struct View: SwiftUI.View {
		let store: StoreOf<InteractionReviewCommon.Proofs>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(alignment: .leading, spacing: .medium2) {
					HStack {
						Text(L10n.TransactionReview.presentingHeading)
							.sectionHeading
							.textCase(.uppercase)

						InfoButton(.badges)

						Spacer(minLength: 0)
					}

					ForEach(store.proofs) { proof in
						ResourceBalanceView(proof.resourceBalance.viewState, appearance: .compact) {
							store.send(.view(.proofTapped(proof)))
						}
					}
					Separator()
				}
			}
		}
	}
}
