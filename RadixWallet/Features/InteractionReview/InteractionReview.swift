import SwiftUI

// MARK: - InteractionReview
/// Namespace to group every component common to `TransactionReview` and `PreAuthorizationReview`
enum InteractionReview {}

// MARK: InteractionReview.Kind
extension InteractionReview {
	enum Kind: Sendable, Hashable {
		case transaction
		case preAuthorization
	}
}

// MARK: InteractionReview.Transfer
extension InteractionReview {
	typealias Transfer = IDResourceBalance
}
