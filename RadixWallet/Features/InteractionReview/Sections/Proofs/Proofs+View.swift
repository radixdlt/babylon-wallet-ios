import ComposableArchitecture
import SwiftUI

// MARK: - InteractionReviewProofs.View
extension InteractionReview.Proofs {
	struct View: SwiftUI.View {
		let store: StoreOf<InteractionReview.Proofs>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(alignment: .leading, spacing: .medium2) {
					HStack {
						Text(L10n.InteractionReview.presentingHeading)
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
					if store.kind == .transaction {
						Separator()
					}
				}
			}
		}
	}
}
