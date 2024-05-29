//
// StateEntityDetailsResponsePackageDetails.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityDetailsResponsePackageDetails")
public typealias StateEntityDetailsResponsePackageDetails = GatewayAPI.StateEntityDetailsResponsePackageDetails

extension GatewayAPI {

/** vm_type, code_hash_hex and code_hex are always going to be empty, use &#x60;codes&#x60; property which will return collection (it&#39;s possible after protocol update that package might have multiple codes) */
public struct StateEntityDetailsResponsePackageDetails: Codable, Hashable {

    public private(set) var type: StateEntityDetailsResponseItemDetailsType
    public private(set) var codes: PackageCodeCollection
    public private(set) var vmType: PackageVmType
    /** Hex-encoded binary blob. */
    public private(set) var codeHashHex: String
    /** Hex-encoded binary blob. */
    public private(set) var codeHex: String
    /** String-encoded decimal representing the amount of a related fungible resource. */
    public private(set) var royaltyVaultBalance: String?
    public private(set) var blueprints: PackageBlueprintCollection?
    public private(set) var schemas: EntitySchemaCollection?
    public private(set) var roleAssignments: ComponentEntityRoleAssignments?

    public init(type: StateEntityDetailsResponseItemDetailsType, codes: PackageCodeCollection, vmType: PackageVmType, codeHashHex: String, codeHex: String, royaltyVaultBalance: String? = nil, blueprints: PackageBlueprintCollection? = nil, schemas: EntitySchemaCollection? = nil, roleAssignments: ComponentEntityRoleAssignments? = nil) {
        self.type = type
        self.codes = codes
        self.vmType = vmType
        self.codeHashHex = codeHashHex
        self.codeHex = codeHex
        self.royaltyVaultBalance = royaltyVaultBalance
        self.blueprints = blueprints
        self.schemas = schemas
        self.roleAssignments = roleAssignments
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        case codes
        case vmType = "vm_type"
        case codeHashHex = "code_hash_hex"
        case codeHex = "code_hex"
        case royaltyVaultBalance = "royalty_vault_balance"
        case blueprints
        case schemas
        case roleAssignments = "role_assignments"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(codes, forKey: .codes)
        try container.encode(vmType, forKey: .vmType)
        try container.encode(codeHashHex, forKey: .codeHashHex)
        try container.encode(codeHex, forKey: .codeHex)
        try container.encodeIfPresent(royaltyVaultBalance, forKey: .royaltyVaultBalance)
        try container.encodeIfPresent(blueprints, forKey: .blueprints)
        try container.encodeIfPresent(schemas, forKey: .schemas)
        try container.encodeIfPresent(roleAssignments, forKey: .roleAssignments)
    }
}

}
