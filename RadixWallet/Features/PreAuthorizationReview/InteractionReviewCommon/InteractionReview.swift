import SwiftUI

// MARK: - InteractionReviewCommon
/// Namespace to group every component common to `TransactionReview` and `PreAuthorizationReview`
enum InteractionReviewCommon {}

// MARK: InteractionReviewCommon.Kind
extension InteractionReviewCommon {
	enum Kind: Sendable, Hashable {
		case transaction
		case preAuthorization
	}
}
