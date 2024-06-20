import ComposableArchitecture
import SwiftUI

// MARK: - Completion
struct Completion: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let txID: IntentHash?
		let dappMetadata: DappMetadata
		let isDeepLinkRequest: Bool

		init(
			txID: IntentHash?,
			dappMetadata: DappMetadata,
			isDeepLinkRequest: Bool
		) {
			self.txID = txID
			self.dappMetadata = dappMetadata
			self.isDeepLinkRequest = isDeepLinkRequest
		}
	}

	enum ViewAction: Sendable, Equatable {
		case dismissTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .dismissTapped:
			.send(.delegate(.dismiss))
		}
	}
}
