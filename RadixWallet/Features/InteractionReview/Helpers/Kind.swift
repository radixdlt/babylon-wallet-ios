import Foundation

// MARK: InteractionReview.Kind
extension InteractionReview {
	enum Kind: Sendable, Hashable {
		case transaction
		case preAuthorization
	}
}
