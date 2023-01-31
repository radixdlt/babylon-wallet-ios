import FeaturePrelude

// MARK: - DappConnectionRequest.State
public extension DappConnectionRequest {
	struct State: Equatable {
		public let request: P2P.OneTimeAccountsRequestToHandle

		public init(
			request: P2P.OneTimeAccountsRequestToHandle
		) {
			self.request = request
		}
	}
}

#if DEBUG
public extension DappConnectionRequest.State {
	static var previewValue: Self { .init(request: .init(request: .previewValueOneTimeAccountAccess)!) }
}
#endif
