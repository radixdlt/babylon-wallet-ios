import DappInteractionFeature
import FeaturePrelude
import TransactionSigningFeature

// MARK: - HandleDappRequests.State
public extension HandleDappRequests {
	struct State: Hashable {
//		public var currentRequest: P2P.UnfinishedRequestFromClient?
		public var unfinishedRequestsFromClient: P2P.UnfinishedRequestsFromClient

		public init(
			//			currentRequest: P2P.UnfinishedRequestFromClient? = nil,
			unfinishedRequestsFromClient: P2P.UnfinishedRequestsFromClient = .init()
		) {
//			self.currentRequest = currentRequest
			self.unfinishedRequestsFromClient = unfinishedRequestsFromClient
		}
	}
}
