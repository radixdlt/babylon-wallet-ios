import FeaturePrelude
import GrantDappWalletAccessFeature
import Profile
import TransactionSigningFeature

// MARK: - HandleDappRequests.State
public extension HandleDappRequests {
	struct State: Equatable {
		public var currentRequest: CurrentRequest?
		public var unfinishedRequestsFromClient: P2P.UnfinishedRequestsFromClient

		public init(
			unfinishedRequestsFromClient: P2P.UnfinishedRequestsFromClient = .init(),
			currentRequest: CurrentRequest? = nil
		) {
			self.currentRequest = currentRequest
			self.unfinishedRequestsFromClient = unfinishedRequestsFromClient
		}
	}
}

// MARK: - Home.State.HandleRequest
public extension HandleDappRequests.State {
	var chooseAccounts: ChooseAccounts.State? {
		get {
			guard let currentRequest else { return nil }
			switch currentRequest {
			case let .chooseAccounts(state):
				return state
			default: return nil
			}
		}
		set {
			if let newValue {
				currentRequest = .chooseAccounts(newValue)
			} else {
				currentRequest = nil
			}
		}
	}

	var transactionSigning: TransactionSigning.State? {
		get {
			guard let currentRequest else { return nil }
			switch currentRequest {
			case let .transactionSigning(state):
				return state
			default: return nil
			}
		}
		set {
			if let newValue {
				currentRequest = .transactionSigning(newValue)
			} else {
				currentRequest = nil
			}
		}
	}

	enum CurrentRequest: Equatable {
		case transactionSigning(TransactionSigning.State)
		case chooseAccounts(ChooseAccounts.State)

		public init(requestItemToHandle: P2P.RequestItemToHandle) {
			switch requestItemToHandle.requestItem {
			case let .oneTimeAccounts(item):
				self = .chooseAccounts(
					.init(request:
						.init(
							requestItem: item,
							parentRequest: requestItemToHandle.parentRequest
						)
					)
				)
			case let .sendTransaction(item):
				self = .transactionSigning(
					.init(
						request: .init(
							requestItem: item,
							parentRequest: requestItemToHandle.parentRequest
						)
					)
				)
			}
		}
	}
}
