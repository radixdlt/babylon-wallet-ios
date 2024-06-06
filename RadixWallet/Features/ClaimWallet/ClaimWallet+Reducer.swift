import ComposableArchitecture
import SwiftUI

// MARK: - NewConnectionApproval
public struct ClaimWallet: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var isLoading: Bool = false

		public var screenState: ControlState {
			isLoading ? .loading(.global(text: nil)) : .enabled
		}

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case clearWalletButtonTapped
		case transferBackButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case didClearWallet
		case transferBack
		case dismiss
	}

	@Dependency(\.resetWalletClient) var resetWalletClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .clearWalletButtonTapped:
			return .run { send in
				await resetWalletClient.resetWallet()
				await send(.delegate(.didClearWallet))
			}
		case .transferBackButtonTapped:
			state.isLoading = true
			return .send(.delegate(.transferBack))
		}
	}
}
