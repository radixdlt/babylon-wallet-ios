//
// GatewayInfoResponseKnownTarget.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import ClientPrelude
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.GatewayInfoResponseKnownTarget")
public typealias GatewayInfoResponseKnownTarget = GatewayAPI.GatewayInfoResponseKnownTarget

// MARK: - GatewayAPI.GatewayInfoResponseKnownTarget
extension GatewayAPI {
	public struct GatewayInfoResponseKnownTarget: Codable, Hashable {
		/** The latest-seen state version of the tip of the network's ledger. If this is significantly ahead of the current LedgerState version, the Network Gateway is possibly behind and may be reporting outdated information.  */
		public private(set) var stateVersion: Int64

		public init(stateVersion: Int64) {
			self.stateVersion = stateVersion
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case stateVersion = "state_version"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(stateVersion, forKey: .stateVersion)
		}
	}
}
