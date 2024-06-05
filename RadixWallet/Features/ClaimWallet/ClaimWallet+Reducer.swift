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
				print("•• CLAIMWALLET clearWalletButtonTapped")
				await resetWalletClient.resetWallet()
				print("•• CLAIMWALLET will send delegate(.didClearWallet)")
				await send(.delegate(.didClearWallet))
			}
		case .transferBackButtonTapped:
			state.isLoading = true
			return .run { send in
				print("•• CLAIMWALLET transferBackButtonTapped")
				try await Task.sleep(for: .seconds(2))
				print("•• CLAIMWALLET will send delegate(.didTransferBack)")
				await send(.delegate(.didTransferBack))
			}
		}
	}
}
