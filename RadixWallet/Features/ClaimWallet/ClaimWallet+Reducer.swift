import ComposableArchitecture
import SwiftUI

// MARK: - NewConnectionApproval
public struct ClaimWallet: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var isLoading: Bool

		public init(
			isLoading: Bool = false
		) {
			self.isLoading = isLoading
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case clearWalletButtonTapped
		case transferBackButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .clearWalletButtonTapped:
			// TODO: clear wallet
			.send(.delegate(.dismiss))

		case .transferBackButtonTapped:
			// TODO: transfer back
			.send(.delegate(.dismiss))
		}
	}
}
