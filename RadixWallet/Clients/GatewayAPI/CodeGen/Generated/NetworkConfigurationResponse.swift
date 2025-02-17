//
// NetworkConfigurationResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.NetworkConfigurationResponse")
typealias NetworkConfigurationResponse = GatewayAPI.NetworkConfigurationResponse

extension GatewayAPI {

struct NetworkConfigurationResponse: Codable, Hashable {

    /** The logical id of the network */
    private(set) var networkId: Int
    /** The logical name of the network */
    private(set) var networkName: String
    private(set) var wellKnownAddresses: NetworkConfigurationResponseWellKnownAddresses

    init(networkId: Int, networkName: String, wellKnownAddresses: NetworkConfigurationResponseWellKnownAddresses) {
        self.networkId = networkId
        self.networkName = networkName
        self.wellKnownAddresses = wellKnownAddresses
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case networkId = "network_id"
        case networkName = "network_name"
        case wellKnownAddresses = "well_known_addresses"
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(networkId, forKey: .networkId)
        try container.encode(networkName, forKey: .networkName)
        try container.encode(wellKnownAddresses, forKey: .wellKnownAddresses)
    }
}

}
