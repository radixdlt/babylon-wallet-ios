//
// BlueprintRoyaltyConfig.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.BlueprintRoyaltyConfig")
public typealias BlueprintRoyaltyConfig = GatewayAPI.BlueprintRoyaltyConfig

extension GatewayAPI {

public struct BlueprintRoyaltyConfig: Codable, Hashable {

    public private(set) var isEnabled: Bool
    /** The royalty rules by method. The array is only present if royalties are enabled. */
    public private(set) var methodRules: [BlueprintMethodRoyalty]?

    public init(isEnabled: Bool, methodRules: [BlueprintMethodRoyalty]? = nil) {
        self.isEnabled = isEnabled
        self.methodRules = methodRules
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case isEnabled = "is_enabled"
        case methodRules = "method_rules"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encodeIfPresent(methodRules, forKey: .methodRules)
    }
}

}
