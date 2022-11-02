import ComposableArchitecture
import Foundation
import IncomingConnectionRequestFromDappReviewFeature // FIXME: only models, move to seperate package..?
import Profile

// MARK: - BrowerExtensionsConnectivity
public struct BrowerExtensionsConnectivity: ReducerProtocol {
	@Dependency(\.profileClient) var profileClient
	public init() {}
}

public extension BrowerExtensionsConnectivity {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		.none
	}
}

// MARK: BrowerExtensionsConnectivity.State
public extension BrowerExtensionsConnectivity {
	struct State: Equatable {
		public init() {}
	}
}

// MARK: BrowerExtensionsConnectivity.Action
public extension BrowerExtensionsConnectivity {
	enum Action: Equatable {
		case delegate(DelegateAction)
	}
}

// MARK: - BrowerExtensionsConnectivity.Action.DelegateAction
public extension BrowerExtensionsConnectivity.Action {
	enum DelegateAction: Equatable {
		case receivedMessageFromBrowser(IncomingMessageFromBrowser)
	}
}

// MARK: - IncomingMessageFromBrowser
public struct IncomingMessageFromBrowser: Sendable, Equatable {
	public let requestMethodWalletRequest: RequestMethodWalletRequest
	public let browserExtensionConnection: BrowserExtensionConnection
}
