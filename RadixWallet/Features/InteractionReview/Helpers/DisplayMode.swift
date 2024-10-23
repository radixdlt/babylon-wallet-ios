import Foundation

extension InteractionReview {
	enum DisplayMode: Sendable, Hashable {
		case detailed
		case raw(String)

		var rawTransaction: String? {
			guard case let .raw(transaction) = self else { return nil }
			return transaction
		}
	}
}
