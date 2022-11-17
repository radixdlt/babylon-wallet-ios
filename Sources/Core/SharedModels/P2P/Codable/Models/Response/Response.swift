//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-11-16.
//

import Foundation

// MARK: - P2P.ToDapp.Response
public extension P2P.ToDapp {
	/// Called `WalletResponse` in [CAP21][cap]
	///
	/// [cap]: https://radixdlt.atlassian.net/wiki/spaces/AT/pages/2712895489/CAP-21+Message+format+between+dApp+and+wallet#Wallet-SDK-%E2%86%94%EF%B8%8F-Wallet-messages
	///
	struct Response: Sendable, Hashable, Encodable, Identifiable {
		/// *MUST* match an ID from an incoming request from Dapp.
		public let id: P2P.FromDapp.Request.ID

		public let items: [WalletResponseItem]

		private init(
			id: P2P.FromDapp.Request.ID,
			items: [WalletResponseItem]
		) {
			self.id = id
			self.items = items
		}
	}
}

public extension P2P.ToDapp.Response {
	static func to(
		request: P2P.FromDapp.Request,
		items responseItems: [P2P.ToDapp.WalletResponseItem]
	) throws -> Self {
		guard responseItems.count == request.items.count else {
			throw InvalidNumberOfResponseItems()
		}
		return Self(id: request.id, items: responseItems)
	}

	struct InvalidNumberOfResponseItems: Swift.Error {}
}

public extension P2P.ToDapp.Response {
	private enum CodingKeys: String, CodingKey {
		case id = "requestId"
		case items = "payload"
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(items, forKey: .items)
	}
}
