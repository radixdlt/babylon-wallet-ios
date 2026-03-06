import Foundation

// MARK: InteractionReview.Kind
extension InteractionReview {
	enum Kind: Hashable {
		case transaction
		case preAuthorization
	}
}
