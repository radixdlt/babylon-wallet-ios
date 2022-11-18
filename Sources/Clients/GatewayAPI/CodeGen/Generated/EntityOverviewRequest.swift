//
// EntityOverviewRequest.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

// MARK: - EntityOverviewRequest
public struct EntityOverviewRequest: Codable, Hashable {
	public private(set) var addresses: [String]
	public private(set) var atStateIdentifier: PartialLedgerStateIdentifier?

	public init(addresses: [String], atStateIdentifier: PartialLedgerStateIdentifier? = nil) {
		self.addresses = addresses
		self.atStateIdentifier = atStateIdentifier
	}

	public enum CodingKeys: String, CodingKey, CaseIterable {
		case addresses
		case atStateIdentifier = "at_state_identifier"
	}

	// Encodable protocol methods

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(addresses, forKey: .addresses)
		try container.encodeIfPresent(atStateIdentifier, forKey: .atStateIdentifier)
	}
}
