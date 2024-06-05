import ComposableArchitecture
import SwiftUI

// MARK: - NewConnectionApproval
public struct ClaimWallet: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var isLoading: Bool

		public var screenState: ControlState {
			isLoading ? .loading(.global(text: nil)) : .enabled
		}

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
		case didClearWallet
		case didTransferBack
		case dismiss
	}

	@Dependency(\.resetWalletClient) var resetWalletClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .clearWalletButtonTapped:
			return .run { send in
				print("•• CLAIMWALLET will do resetWalletClient.resetWallet")
				await resetWalletClient.resetWallet()
//				await send(.delegate(.dismiss))
				print("•• CLAIMWALLET will send delegate(.didClearWallet)")
				await send(.delegate(.didClearWallet))
			}
		case .transferBackButtonTapped:
			// TODO: transfer back
			print("•• CLAIMWALLET will send delegate(.dismiss)")
			return .send(.delegate(.dismiss))
//			.send(.delegate(.didTransferBack))
		}
	}
}
