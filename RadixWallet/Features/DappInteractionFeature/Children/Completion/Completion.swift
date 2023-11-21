import ComposableArchitecture
import SwiftUI

// MARK: - Completion
struct Completion: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let txID: TXID?
		let dappMetadata: DappMetadata

		init(
			txID: TXID?,
			dappMetadata: DappMetadata
		) {
			self.txID = txID
			self.dappMetadata = dappMetadata
		}
	}

	enum ViewAction: Sendable, Equatable {
		case dismissTapped
	}

	@Dependency(\.dismiss) var dismiss

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .dismissTapped:
			.run { _ in
				await dismiss()
			}
		}
	}
}
