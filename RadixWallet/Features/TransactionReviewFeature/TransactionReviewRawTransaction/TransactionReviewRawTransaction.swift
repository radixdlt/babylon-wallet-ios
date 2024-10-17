import ComposableArchitecture
import SwiftUI

// MARK: - TransactionReviewRawTransaction
struct TransactionReviewRawTransaction: Sendable, FeatureReducer {
	@Dependency(\.dismiss) var dismiss

	struct State: Sendable, Hashable {
		var transaction: String

		init(transaction: String) {
			self.transaction = transaction
		}
	}

	enum ViewAction: Sendable, Equatable {
		case closeTapped
	}

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeTapped:
			.run { _ in
				await dismiss()
			}
		}
	}
}
