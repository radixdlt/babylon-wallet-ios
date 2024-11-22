import ComposableArchitecture
import SwiftUI

// MARK: - Completion
struct Completion: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let txID: TransactionIntentHash?
		let dappMetadata: DappMetadata
		let p2pRoute: P2P.Route
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
