import SwiftUI

// MARK: - InteractionReview
/// Namespace to group every subview common to `TransactionReview` and `PreAuthorizationReview`
enum InteractionReview {}

// MARK: InteractionReview.Kind
extension InteractionReview {
	enum Kind: Sendable, Hashable {
		case transaction
		case preAuthorization
	}
}
