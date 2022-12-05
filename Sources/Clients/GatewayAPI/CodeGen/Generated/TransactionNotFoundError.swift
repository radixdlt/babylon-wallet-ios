//
// TransactionNotFoundError.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionNotFoundError")
public typealias TransactionNotFoundError = GatewayAPI.TransactionNotFoundError

// MARK: - GatewayAPI.TransactionNotFoundError
public extension GatewayAPI {
	struct TransactionNotFoundError: Codable, Hashable {
		/** The type of error. Each subtype may have its own additional structured fields. */
		public private(set) var type: String
		public private(set) var transactionNotFound: TransactionCommittedDetailsRequestIdentifier

		public init(type: String, transactionNotFound: TransactionCommittedDetailsRequestIdentifier) {
			self.type = type
			self.transactionNotFound = transactionNotFound
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case type
			case transactionNotFound = "transaction_not_found"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(type, forKey: .type)
			try container.encode(transactionNotFound, forKey: .transactionNotFound)
		}
	}
}
