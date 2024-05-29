import ComposableArchitecture
import SwiftUI

// MARK: - P2PLink
public struct P2PLinkRow: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = Ed25519PublicKey
		public var id: ID { link.publicKey }
		public let link: P2PLink

		public init(
			link: P2PLink
		) {
			self.link = link
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case deleteConnectionButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case deleteConnection
	}

	public init() {}

	private enum ConnectionUpdateTasksID {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .deleteConnectionButtonTapped:
			.send(.delegate(.deleteConnection))
		}
	}
}
