import FeaturePrelude

// MARK: - DappConnectionRequest.State
public extension DappConnectionRequest {
	struct State: Equatable {
		public let request: P2P.OneTimeAccountAddressesRequestToHandle

		public init(
			request: P2P.OneTimeAccountAddressesRequestToHandle
		) {
			self.request = request
		}
	}
}

public extension DappConnectionRequest.State {
	init(
		request: P2P.RequestFromClient
	) throws {
		try self.init(
			request: .init(request: request)
		)
	}
}

#if DEBUG
public extension DappConnectionRequest.State {
	static var previewValue: Self { try! .init(request: .previewValue) }
}
#endif
