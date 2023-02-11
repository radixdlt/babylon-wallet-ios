//
// TransactionStatusRequestAllOf.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import ClientPrelude
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionStatusRequestAllOf")
public typealias TransactionStatusRequestAllOf = GatewayAPI.TransactionStatusRequestAllOf

// MARK: - GatewayAPI.TransactionStatusRequestAllOf
extension GatewayAPI {
	public struct TransactionStatusRequestAllOf: Codable, Hashable {
		public private(set) var intentHashHex: String?

		public init(intentHashHex: String? = nil) {
			self.intentHashHex = intentHashHex
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case intentHashHex = "intent_hash_hex"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encodeIfPresent(intentHashHex, forKey: .intentHashHex)
		}
	}
}
