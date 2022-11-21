//
// TokenProperties.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TokenProperties")
public typealias TokenProperties = GatewayAPI.TokenProperties

// MARK: - GatewayAPI.TokenProperties
public extension GatewayAPI {
	struct TokenProperties: Codable, Hashable {
		public private(set) var name: String
		public private(set) var description: String
		public private(set) var iconUrl: String
		public private(set) var url: String
		public private(set) var symbol: String
		/** If true, the token is allowed to be minted/burned by the owner. */
		public private(set) var isSupplyMutable: Bool
		/** The string-encoded decimal representing the amount */
		public private(set) var granularity: String
		public private(set) var owner: AccountIdentifier?

		public init(name: String, description: String, iconUrl: String, url: String, symbol: String, isSupplyMutable: Bool, granularity: String, owner: AccountIdentifier? = nil) {
			self.name = name
			self.description = description
			self.iconUrl = iconUrl
			self.url = url
			self.symbol = symbol
			self.isSupplyMutable = isSupplyMutable
			self.granularity = granularity
			self.owner = owner
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case name
			case description
			case iconUrl = "icon_url"
			case url
			case symbol
			case isSupplyMutable = "is_supply_mutable"
			case granularity
			case owner
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(name, forKey: .name)
			try container.encode(description, forKey: .description)
			try container.encode(iconUrl, forKey: .iconUrl)
			try container.encode(url, forKey: .url)
			try container.encode(symbol, forKey: .symbol)
			try container.encode(isSupplyMutable, forKey: .isSupplyMutable)
			try container.encode(granularity, forKey: .granularity)
			try container.encodeIfPresent(owner, forKey: .owner)
		}
	}
}
