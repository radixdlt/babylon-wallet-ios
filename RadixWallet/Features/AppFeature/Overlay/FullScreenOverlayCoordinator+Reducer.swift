import ComposableArchitecture
import SwiftUI

public struct FullScreenOverlayCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var root: Root.State

		public init(root: Root.State) {
			self.root = root
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case root(Root.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	public struct Root: Sendable, Hashable, Reducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case claimWallet(ClaimWallet.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case claimWallet(ClaimWallet.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.claimWallet, action: /Action.claimWallet) {
				ClaimWallet()
			}
		}
	}

	@Dependency(\.overlayWindowClient) var overlayWindowClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.root, action: /Action.child .. ChildAction.root) {
			Root()
		}
		Reduce(core)
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .root(.claimWallet(.delegate(.didClearWallet))):
			overlayWindowClient.sendDelegateAction(.didClearWallet)
			return .send(.delegate(.dismiss))

		case .root(.claimWallet(.delegate(.didTransferBack))):
			return .send(.delegate(.dismiss))

		default:
			return .none
		}
	}
}
