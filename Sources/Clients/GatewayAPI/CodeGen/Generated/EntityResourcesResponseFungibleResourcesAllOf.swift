//
// EntityResourcesResponseFungibleResourcesAllOf.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

// MARK: - EntityResourcesResponseFungibleResourcesAllOf
public struct EntityResourcesResponseFungibleResourcesAllOf: Codable, Hashable {
	public private(set) var items: [EntityResourcesResponseFungibleResourcesItem]

	public init(items: [EntityResourcesResponseFungibleResourcesItem]) {
		self.items = items
	}

	public enum CodingKeys: String, CodingKey, CaseIterable {
		case items
	}

	// Encodable protocol methods

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(items, forKey: .items)
	}
}
