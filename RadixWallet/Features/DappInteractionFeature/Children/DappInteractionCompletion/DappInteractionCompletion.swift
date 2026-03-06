import ComposableArchitecture
import SwiftUI

// MARK: - DappInteractionCompletion
struct DappInteractionCompletion: FeatureReducer {
	struct State: Hashable {
		let kind: Kind
		let dappMetadata: DappMetadata
		let p2pRoute: P2P.Route
	}

	enum ViewAction: Equatable {
		case dismissTapped
	}

	enum DelegateAction: Equatable {
		case dismiss
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .dismissTapped:
			.send(.delegate(.dismiss))
		}
	}
}

typealias DappInteractionCompletionKind = DappInteractionCompletion.State.Kind

// MARK: - DappInteractionCompletion.State.Kind
extension DappInteractionCompletion.State {
	enum Kind: Hashable {
		/// Completion view shown after an authorized/unauthorized dApp interaction.
		case personaData

		/// Completion view shown after a transaction dApp interaction.
		case transaction(TransactionIntentHash)
	}
}
