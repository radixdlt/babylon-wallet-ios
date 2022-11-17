//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-11-16.
//

import Foundation

// MARK: - P2P.FromDapp.OneTimeAccountAddressesRequest
public extension P2P.FromDapp {
	struct OneTimeAccountAddressesRequest:
		Sendable,
		Hashable,
		Decodable,
		P2PFromDappWalletRequestItemProtocol
	{
		public let isRequiringOwnershipProof: Bool
		public let numberOfAddresses: Mode
	}
}

public extension P2P.FromDapp.OneTimeAccountAddressesRequest {
	private enum CodingKeys: String, CodingKey {
		case isRequiringOwnershipProof = "proofOfOwnership"
		case numberOfAddresses
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		try self.init(
			isRequiringOwnershipProof: container.decode(Bool.self, forKey: .isRequiringOwnershipProof),
			numberOfAddresses: .init(maybeUInt: container.decodeIfPresent(UInt.self, forKey: .numberOfAddresses))
		)
	}
}

// MARK: - P2P.FromDapp.OneTimeAccountAddressesRequest.Mode
public extension P2P.FromDapp.OneTimeAccountAddressesRequest {
	enum Mode: Sendable, Hashable {
		case oneOrMore
		case exactly(NumberOfAddresses)
	}
}

public extension P2P.FromDapp.OneTimeAccountAddressesRequest.Mode {
	init(maybeUInt: UInt?) throws {
		if let uint = maybeUInt {
			self = try .exactly(.init(oneOrMore: uint))
		} else {
			self = .oneOrMore
		}
	}

	struct NumberOfAddresses: Sendable, Hashable {
		public let oneOrMore: UInt
		public init(oneOrMore: UInt) throws {
			guard oneOrMore >= 1 else {
				throw ExpectedOneOrMore()
			}
			self.oneOrMore = oneOrMore
		}

		struct ExpectedOneOrMore: Swift.Error {}
	}
}
