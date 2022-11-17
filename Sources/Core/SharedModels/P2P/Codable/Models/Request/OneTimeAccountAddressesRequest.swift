//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-11-16.
//

import Foundation

// MARK: - P2P.FromDapp.OneTimeAccountAddressesRequest
public extension P2P.FromDapp {
	struct OneTimeAccountAddressesRequest: Sendable, Hashable, Decodable, P2PFromDappWalletRequestItemProtocol {
		public let proofOfOwnership: Bool
		public let numberOfAddresses: Mode
	}
}

// MARK: - P2P.FromDapp.OneTimeAccountAddressesRequest.Mode
public extension P2P.FromDapp.OneTimeAccountAddressesRequest {
	enum Mode: Sendable, Hashable, Codable {
		case oneOrMore
		case exactly(NumberOfAddresses)
	}
}

public extension P2P.FromDapp.OneTimeAccountAddressesRequest.Mode {
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

	func encode(to encoder: Encoder) throws {
		switch self {
		case .oneOrMore:
			break
		case let .exactly(oneOrMore):
			var container = encoder.singleValueContainer()
			try container.encode(oneOrMore.oneOrMore)
		}
	}

	init(from decoder: Decoder) throws {
		guard
			let container = try? decoder.singleValueContainer(),
			let oneOrMore = try? container.decode(UInt.self)
		else {
			self = .oneOrMore
			return
		}
		self = try .exactly(NumberOfAddresses(oneOrMore: oneOrMore))
	}
}
