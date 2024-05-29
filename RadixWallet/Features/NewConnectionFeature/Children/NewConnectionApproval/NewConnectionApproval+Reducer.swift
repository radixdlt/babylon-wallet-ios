import ComposableArchitecture
import SwiftUI

// MARK: - NewConnectionApproval
public struct NewConnectionApproval: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let purpose: Purpose
		public var isConnecting: Bool

		public init(
			purpose: Purpose,
			isConnecting: Bool = false
		) {
			self.purpose = purpose
			self.isConnecting = isConnecting
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case dismissButtonTapped
		case continueButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case approved(State.Purpose)
	}

	@Dependency(\.dismiss) var dismiss

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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
	public enum Purpose: Sendable, Hashable {
		case approveNewConnection
		case approveExisitingConnection(NewConnection.State.ConnectionName)
		case approveRelinkAfterProfileRestore
		case approveRelinkAfterUpdate
	}
}
