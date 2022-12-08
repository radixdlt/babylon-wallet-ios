//
// EntityDetailsResponseComponentDetails.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.EntityDetailsResponseComponentDetails")
public typealias EntityDetailsResponseComponentDetails = GatewayAPI.EntityDetailsResponseComponentDetails

// MARK: - GatewayAPI.EntityDetailsResponseComponentDetails
public extension GatewayAPI {
	struct EntityDetailsResponseComponentDetails: Codable, Hashable {
		public private(set) var discriminator: EntityDetailsResponseDetailsType
		/** The Bech32m-encoded human readable version of the entity's global address. */
		public private(set) var packageAddress: String
		public private(set) var blueprintName: String
		public private(set) var state: AnyCodable
		public private(set) var accessRulesChain: AnyCodable

		public init(discriminator: EntityDetailsResponseDetailsType, packageAddress: String, blueprintName: String, state: AnyCodable, accessRulesChain: AnyCodable) {
			self.discriminator = discriminator
			self.packageAddress = packageAddress
			self.blueprintName = blueprintName
			self.state = state
			self.accessRulesChain = accessRulesChain
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case discriminator
			case packageAddress = "package_address"
			case blueprintName = "blueprint_name"
			case state
			case accessRulesChain = "access_rules_chain"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(discriminator, forKey: .discriminator)
			try container.encode(packageAddress, forKey: .packageAddress)
			try container.encode(blueprintName, forKey: .blueprintName)
			try container.encode(state, forKey: .state)
			try container.encode(accessRulesChain, forKey: .accessRulesChain)
		}
	}
}
