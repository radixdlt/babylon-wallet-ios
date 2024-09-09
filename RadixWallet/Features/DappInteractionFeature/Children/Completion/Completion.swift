import ComposableArchitecture
import SwiftUI

// MARK: - Completion
struct Completion: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let txID: IntentHash?
		let dappMetadata: DappMetadata
		let p2pRoute: P2P.Route

		init(
			txID: IntentHash?,
			dappMetadata: DappMetadata,
			p2pRoute: P2P.Route
		) {
			self.txID = txID
			self.dappMetadata = dappMetadata
			self.p2pRoute = p2pRoute
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
