

public extension P2P.ToDapp.Response {
	struct Failure: Sendable, Hashable, Encodable, Identifiable {
		/// *MUST* match an ID from an incoming request from Dapp.
		public let id: P2P.FromDapp.Request.ID

		public let kind: P2P.ToDapp.Response.Failure.Kind
		public let message: String?

		public init(
			id: P2P.FromDapp.Request.ID,
			kind: P2P.ToDapp.Response.Failure.Kind,
			message: String?
		) {
			self.id = id
			self.kind = kind
			self.message = message
		}

		public static func rejected(_ request: P2P.FromDapp.Request) -> Self {
			Self(id: request.id, kind: .rejectedByUser, message: nil)
		}

		public static func request(_ request: P2P.FromDapp.Request, failedWithError error: Kind.Error, message: String?) -> Self {
			Self(id: request.id, kind: .error(error), message: message)
		}
	}
}
