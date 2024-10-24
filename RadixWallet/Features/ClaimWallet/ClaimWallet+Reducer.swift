import ComposableArchitecture
import SwiftUI

// MARK: - NewConnectionApproval
struct ClaimWallet: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var isLoading: Bool = false

		var screenState: ControlState {
			isLoading ? .loading(.global(text: nil)) : .enabled
		}

		init() {}
	}

	enum ViewAction: Sendable, Equatable {
		case clearWalletButtonTapped
		case transferBackButtonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case didClearWallet
		case transferBack
	}

	@Dependency(\.resetWalletClient) var resetWalletClient

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .clearWalletButtonTapped:
			state.isLoading = true
			return .run { send in
				await resetWalletClient.resetWallet()
				await send(.delegate(.didClearWallet))
			}
		case .transferBackButtonTapped:
			return .send(.delegate(.transferBack))
		}
	}
}
