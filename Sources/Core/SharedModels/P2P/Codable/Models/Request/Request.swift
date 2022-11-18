//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-11-16.
//

import EngineToolkit
import Foundation
import Tagged

// MARK: - P2P.FromDapp.Request
public extension P2P.FromDapp {
	/// Called `WalletRequest` in [CAP21][cap]
	///
	/// [cap]: https://radixdlt.atlassian.net/wiki/spaces/AT/pages/2712895489/CAP-21+Message+format+between+dApp+and+wallet#Wallet-SDK-%E2%86%94%EF%B8%8F-Wallet-messages
	///
	struct Request: Sendable, Hashable, Decodable, Identifiable {
		public let id: ID

		public let items: [WalletRequestItem]

		public let metadata: Metadata

		public init(
			id: ID,
			metadata: Metadata,
			items: [WalletRequestItem]
		) {
			self.id = id
			self.metadata = metadata
			self.items = items
		}
	}
}

public extension P2P.FromDapp.Request {
	enum IDTag: Hashable {}
	typealias ID = Tagged<IDTag, String>
}

// MARK: - P2P.FromDapp.Request.Metadata
public extension P2P.FromDapp.Request {
	struct Metadata: Sendable, Hashable, Decodable {
		public let networkId: NetworkID
		public let origin: Origin
		public let dAppId: DAppID

		public init(networkId: NetworkID, origin: Origin, dAppId: DAppID) {
			self.networkId = networkId
			self.origin = origin
			self.dAppId = dAppId
		}
	}
}

public extension P2P.FromDapp.Request.Metadata {
	enum OriginTag: Hashable {}
	typealias Origin = Tagged<OriginTag, String>
	enum DappIDTag: Hashable {}
	typealias DAppID = Tagged<DappIDTag, String>
}

public extension P2P.FromDapp.Request {
	private enum CodingKeys: String, CodingKey {
		case id = "requestId"
		case items = "payload"
		case metadata
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		try self.init(
			id: container.decode(ID.self, forKey: .id),
			metadata: container.decode(Metadata.self, forKey: .metadata),
			items: container.decode([P2P.FromDapp.WalletRequestItem].self, forKey: .items)
		)
	}
}

#if DEBUG
public extension P2P.FromDapp.OneTimeAccountAddressesRequest {
	static let placeholder: Self = .init(
		numberOfAddresses: 1,
		isRequiringOwnershipProof: false
	)
}

public extension P2P.FromDapp.Request {
	static let placeholderOneTimeAccount: Self = .init(
		id: ID("deadbeef-1234"),
		metadata: .init(
			networkId: .primary,
			origin: "Placeholder",
			dAppId: "Placeholder"
		),
		items: [
			.oneTimeAccountAddresses(.placeholder),
		]
	)
}
#endif // DEBUG
