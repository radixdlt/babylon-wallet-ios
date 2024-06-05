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
			case verifyDapp(VerifyDapp.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case claimWallet(ClaimWallet.Action)
			case verifyDapp(VerifyDapp.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: \.claimWallet, action: \.claimWallet) {
				ClaimWallet()
			}
			Scope(state: \.verifyDapp, action: \.verifyDapp) {
				VerifyDapp()
			}
		}
	}

	@Dependency(\.openURL) var openURL

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
			dismiss()

		case let .root(.verifyDapp(.delegate(.continueFlow(url)))):
			openUrl(url).merge(with: dismiss())

		case .root(.verifyDapp(.delegate(.cancel))):
			dismiss()

		default:
			.none
		}
	}

	private func dismiss() -> Effect<Action> {
		.send(.delegate(.dismiss))
	}

	private func openUrl(_ url: URL) -> Effect<Action> {
		.run { _ in
			await openURL(url)
		}
	}
}
