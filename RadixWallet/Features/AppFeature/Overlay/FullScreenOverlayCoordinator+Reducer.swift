import ComposableArchitecture
import SwiftUI

public struct FullScreenOverlayCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var root: Root.State

		public init(root: Root.State) {
			self.root = root
		}
	}

	@CasePathable
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
			case relinkConnector(NewConnection.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case claimWallet(ClaimWallet.Action)
			case relinkConnector(NewConnection.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: \.claimWallet, action: \.claimWallet) {
				ClaimWallet()
			}
			Scope(state: /State.relinkConnector, action: /Action.relinkConnector) {
				NewConnection()
			}
		}
	}

	@Dependency(\.userDefaults) var userDefaults
	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.root, action: \.child.root) {
			Root()
		}
		Reduce(core)
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .root(.claimWallet(.delegate)):
			return .send(.delegate(.dismiss))

		case let .root(.relinkConnector(.delegate(.newConnection(connectedClient)))):
			userDefaults.setShowRelinkConnectorsAfterProfileRestore(false)
			userDefaults.setShowRelinkConnectorsAfterUpdate(false)
			return .run { send in
				try await radixConnectClient.updateOrAddP2PLink(connectedClient)
				await send(.delegate(.dismiss))
			} catch: { error, _ in
				loggerGlobal.error("Failed P2PLink, error \(error)")
				errorQueue.schedule(error)
			}

		default:
			return .none
		}
	}
}
