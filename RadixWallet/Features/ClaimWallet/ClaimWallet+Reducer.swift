import ComposableArchitecture
import SwiftUI

// MARK: - NewConnectionApproval
public struct ClaimWallet: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var isLoading: Bool = false
		public var failedToReclaim: Bool = false

		public var screenState: ControlState {
			isLoading ? .loading(.global(text: nil)) : .enabled
		}

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case clearWalletButtonTapped
		case transferBackButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case failedToReclaim
	}

	public enum DelegateAction: Sendable, Equatable {
		case didClearWallet
		case didTransferBack
		case dismiss
	}

	@Dependency(\.resetWalletClient) var resetWalletClient
	@Dependency(\.cloudBackupClient) var cloudBackupClient

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
			state.failedToReclaim = false
			return .run { send in
				do {
					try await cloudBackupClient.reclaimProfile()
					await send(.delegate(.didTransferBack))
				} catch {
					await send(.internal(.failedToReclaim))
				}
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .failedToReclaim:
			state.isLoading = false
			state.failedToReclaim = true
			return .none
		}
	}
}
