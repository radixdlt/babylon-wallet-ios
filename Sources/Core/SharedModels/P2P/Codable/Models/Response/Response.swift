import Foundation

// MARK: - P2P.ToDapp.Response
public extension P2P.ToDapp {
	enum Response: Sendable, Hashable, Encodable, Identifiable {
		case success(Success)
		case failure(Failure)
	}
}

public extension P2P.ToDapp.Response {
	/// Called `WalletResponse` in [CAP21][cap]
	///
	/// [cap]: https://radixdlt.atlassian.net/wiki/spaces/AT/pages/2712895489/CAP-21+Message+format+between+dApp+and+wallet#Wallet-SDK-%E2%86%94%EF%B8%8F-Wallet-messages
	///
	struct Success: Sendable, Hashable, Encodable, Identifiable {
		/// *MUST* match an ID from an incoming request from Dapp.
		public let id: P2P.FromDapp.Request.ID

		public let items: [P2P.ToDapp.WalletResponseItem]

		public init(
			id: P2P.FromDapp.Request.ID,
			items: [P2P.ToDapp.WalletResponseItem]
		) {
			self.id = id
			self.items = items
		}
	}

	struct Failure: Sendable, Hashable, Encodable, Identifiable {
		/// *MUST* match an ID from an incoming request from Dapp.
		public let id: P2P.FromDapp.Request.ID
		public let error: P2P.ToDapp.Error
		public let message: String?
		public init(id: P2P.FromDapp.Request.ID, error: P2P.ToDapp.Error, message: String?) {
			self.id = id
			self.error = error
			self.message = message
		}
	}
}

// MARK: - P2P.ToDapp.Error
public extension P2P.ToDapp {
	enum Error: String, Swift.Error, Sendable, Encodable, Hashable {
		case rejectedByUser
	}
}

public extension P2P.ToDapp.Response {
	static func reject(
		request: P2P.FromDapp.Request
	) -> Self {
		.failure(.init(id: request.id, error: .rejectedByUser, message: nil))
	}

	static func to(
		request: P2P.FromDapp.Request,
		items responseItems: [P2P.ToDapp.WalletResponseItem]
	) throws -> Self {
		guard responseItems.count == request.items.count else {
			throw InvalidNumberOfResponseItems()
		}
		return .success(.init(id: request.id, items: responseItems))
	}

	struct InvalidNumberOfResponseItems: Swift.Error {}
}

public extension P2P.ToDapp.Response.Success {
	private enum CodingKeys: String, CodingKey {
		case id = "requestId"
		case items
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(items, forKey: .items)
		try container.encode(id, forKey: .id)
	}
}

public extension P2P.ToDapp.Response.Failure {
	private enum CodingKeys: String, CodingKey {
		case id = "requestId"
		case message
		case error
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(id, forKey: .id)
		try container.encode(error, forKey: .error)
		try container.encodeIfPresent(message, forKey: .message)
	}
}

public extension P2P.ToDapp.Response {
	var id: P2P.FromDapp.Request.ID {
		switch self {
		case let .failure(failure):
			return failure.id
		case let .success(success):
			return success.id
		}
	}

	func encode(to encoder: Encoder) throws {
		switch self {
		case let .failure(failure):
			try failure.encode(to: encoder)
		case let .success(success):
			try success.encode(to: encoder)
		}
	}
}
