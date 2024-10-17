//
// NativeResourceAccessControllerRecoveryBadgeValue.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.NativeResourceAccessControllerRecoveryBadgeValue")
typealias NativeResourceAccessControllerRecoveryBadgeValue = GatewayAPI.NativeResourceAccessControllerRecoveryBadgeValue

extension GatewayAPI {

struct NativeResourceAccessControllerRecoveryBadgeValue: Codable, Hashable {

    private(set) var kind: NativeResourceKind
    /** Bech32m-encoded human readable version of the address. */
    private(set) var accessControllerAddress: String

    init(kind: NativeResourceKind, accessControllerAddress: String) {
        self.kind = kind
        self.accessControllerAddress = accessControllerAddress
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case kind
        case accessControllerAddress = "access_controller_address"
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .kind)
        try container.encode(accessControllerAddress, forKey: .accessControllerAddress)
    }
}

}
