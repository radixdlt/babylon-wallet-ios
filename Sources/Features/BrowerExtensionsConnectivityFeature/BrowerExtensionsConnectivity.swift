import Foundation
import ComposableArchitecture
import IncomingConnectionRequestFromDappReviewFeature // FIXME: only models, move to seperate package..?
import Profile

public struct BrowerExtensionsConnectivity: ReducerProtocol {
	@Dependency(\.profileClient) var profileClient
	public init() {}
}

public extension BrowerExtensionsConnectivity {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		return .none
	}
}

public extension BrowerExtensionsConnectivity {
	struct State: Equatable {
		public init() {}
	}
}

public extension BrowerExtensionsConnectivity {
	enum Action: Equatable {
		case delegate(DelegateAction)
	}
}

public extension BrowerExtensionsConnectivity.Action {
	enum DelegateAction: Equatable {
		case receivedMessageFromBrowser(IncomingMessageFromBrowser)
	}
}

public struct IncomingMessageFromBrowser: Sendable, Equatable {
	public let requestMethodWalletRequest: RequestMethodWalletRequest
	public let browserExtensionConnection: BrowserExtensionConnection
}
