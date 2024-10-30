import ComposableArchitecture
import SwiftUI

// MARK: - NewConnectionApproval
struct NewConnectionApproval: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let purpose: Purpose
		var isConnecting: Bool

		init(
			purpose: Purpose,
			isConnecting: Bool = false
		) {
			self.purpose = purpose
			self.isConnecting = isConnecting
		}
	}

	enum ViewAction: Sendable, Equatable {
		case dismissButtonTapped
		case continueButtonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case approved(State.Purpose)
	}

	@Dependency(\.dismiss) var dismiss

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .dismissButtonTapped:
			.run { _ in await dismiss() }

		case .continueButtonTapped:
			.send(.delegate(.approved(state.purpose)))
		}
	}
}

// MARK: - NewConnectionApproval.State.Purpose
extension NewConnectionApproval.State {
	enum Purpose: Sendable, Hashable {
		case approveNewConnection
		case approveExisitingConnection(NewConnection.State.ConnectionName)
		case approveRelinkAfterProfileRestore
		case approveRelinkAfterUpdate
	}
}
