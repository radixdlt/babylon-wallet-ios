import SwiftUI

// MARK: - InteractionReview
// Namespace to group every subview common to TransactionReview and PreAuthorizationReview
enum InteractionReview {}

// MARK: InteractionReview.Kind
extension InteractionReview {
	enum Kind: Sendable, Hashable {
		case transaction
		case preAuthorization
	}
}

// MARK: InteractionReview.HeaderView
extension InteractionReview {
	struct HeaderView: View {
		let kind: Kind

		var body: some View {
			EmptyView()
		}
	}
}
