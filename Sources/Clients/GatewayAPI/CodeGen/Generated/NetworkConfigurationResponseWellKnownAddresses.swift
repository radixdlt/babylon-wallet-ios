//
// NetworkConfigurationResponseWellKnownAddresses.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.NetworkConfigurationResponseWellKnownAddresses")
public typealias NetworkConfigurationResponseWellKnownAddresses = GatewayAPI.NetworkConfigurationResponseWellKnownAddresses

extension GatewayAPI {

public struct NetworkConfigurationResponseWellKnownAddresses: Codable, Hashable {

    /** Bech32m-encoded human readable version of the address. */
    public private(set) var xrd: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var secp256k1SignatureVirtualBadge: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var ed25519SignatureVirtualBadge: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var packageOfDirectCallerVirtualBadge: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var globalCallerVirtualBadge: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var systemTransactionBadge: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var packageOwnerBadge: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var validatorOwnerBadge: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var accountOwnerBadge: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var identityOwnerBadge: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var packagePackage: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var resourcePackage: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var accountPackage: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var identityPackage: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var consensusManagerPackage: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var accessControllerPackage: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var transactionProcessorPackage: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var metadataModulePackage: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var royaltyModulePackage: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var accessRulesPackage: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var genesisHelperPackage: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var faucetPackage: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var consensusManager: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var genesisHelper: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var faucet: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var poolPackage: String

    public init(xrd: String, secp256k1SignatureVirtualBadge: String, ed25519SignatureVirtualBadge: String, packageOfDirectCallerVirtualBadge: String, globalCallerVirtualBadge: String, systemTransactionBadge: String, packageOwnerBadge: String, validatorOwnerBadge: String, accountOwnerBadge: String, identityOwnerBadge: String, packagePackage: String, resourcePackage: String, accountPackage: String, identityPackage: String, consensusManagerPackage: String, accessControllerPackage: String, transactionProcessorPackage: String, metadataModulePackage: String, royaltyModulePackage: String, accessRulesPackage: String, genesisHelperPackage: String, faucetPackage: String, consensusManager: String, genesisHelper: String, faucet: String, poolPackage: String) {
        self.xrd = xrd
        self.secp256k1SignatureVirtualBadge = secp256k1SignatureVirtualBadge
        self.ed25519SignatureVirtualBadge = ed25519SignatureVirtualBadge
        self.packageOfDirectCallerVirtualBadge = packageOfDirectCallerVirtualBadge
        self.globalCallerVirtualBadge = globalCallerVirtualBadge
        self.systemTransactionBadge = systemTransactionBadge
        self.packageOwnerBadge = packageOwnerBadge
        self.validatorOwnerBadge = validatorOwnerBadge
        self.accountOwnerBadge = accountOwnerBadge
        self.identityOwnerBadge = identityOwnerBadge
        self.packagePackage = packagePackage
        self.resourcePackage = resourcePackage
        self.accountPackage = accountPackage
        self.identityPackage = identityPackage
        self.consensusManagerPackage = consensusManagerPackage
        self.accessControllerPackage = accessControllerPackage
        self.transactionProcessorPackage = transactionProcessorPackage
        self.metadataModulePackage = metadataModulePackage
        self.royaltyModulePackage = royaltyModulePackage
        self.accessRulesPackage = accessRulesPackage
        self.genesisHelperPackage = genesisHelperPackage
        self.faucetPackage = faucetPackage
        self.consensusManager = consensusManager
        self.genesisHelper = genesisHelper
        self.faucet = faucet
        self.poolPackage = poolPackage
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case xrd
        case secp256k1SignatureVirtualBadge = "secp256k1_signature_virtual_badge"
        case ed25519SignatureVirtualBadge = "ed25519_signature_virtual_badge"
        case packageOfDirectCallerVirtualBadge = "package_of_direct_caller_virtual_badge"
        case globalCallerVirtualBadge = "global_caller_virtual_badge"
        case systemTransactionBadge = "system_transaction_badge"
        case packageOwnerBadge = "package_owner_badge"
        case validatorOwnerBadge = "validator_owner_badge"
        case accountOwnerBadge = "account_owner_badge"
        case identityOwnerBadge = "identity_owner_badge"
        case packagePackage = "package_package"
        case resourcePackage = "resource_package"
        case accountPackage = "account_package"
        case identityPackage = "identity_package"
        case consensusManagerPackage = "consensus_manager_package"
        case accessControllerPackage = "access_controller_package"
        case transactionProcessorPackage = "transaction_processor_package"
        case metadataModulePackage = "metadata_module_package"
        case royaltyModulePackage = "royalty_module_package"
        case accessRulesPackage = "access_rules_package"
        case genesisHelperPackage = "genesis_helper_package"
        case faucetPackage = "faucet_package"
        case consensusManager = "consensus_manager"
        case genesisHelper = "genesis_helper"
        case faucet
        case poolPackage = "pool_package"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(xrd, forKey: .xrd)
        try container.encode(secp256k1SignatureVirtualBadge, forKey: .secp256k1SignatureVirtualBadge)
        try container.encode(ed25519SignatureVirtualBadge, forKey: .ed25519SignatureVirtualBadge)
        try container.encode(packageOfDirectCallerVirtualBadge, forKey: .packageOfDirectCallerVirtualBadge)
        try container.encode(globalCallerVirtualBadge, forKey: .globalCallerVirtualBadge)
        try container.encode(systemTransactionBadge, forKey: .systemTransactionBadge)
        try container.encode(packageOwnerBadge, forKey: .packageOwnerBadge)
        try container.encode(validatorOwnerBadge, forKey: .validatorOwnerBadge)
        try container.encode(accountOwnerBadge, forKey: .accountOwnerBadge)
        try container.encode(identityOwnerBadge, forKey: .identityOwnerBadge)
        try container.encode(packagePackage, forKey: .packagePackage)
        try container.encode(resourcePackage, forKey: .resourcePackage)
        try container.encode(accountPackage, forKey: .accountPackage)
        try container.encode(identityPackage, forKey: .identityPackage)
        try container.encode(consensusManagerPackage, forKey: .consensusManagerPackage)
        try container.encode(accessControllerPackage, forKey: .accessControllerPackage)
        try container.encode(transactionProcessorPackage, forKey: .transactionProcessorPackage)
        try container.encode(metadataModulePackage, forKey: .metadataModulePackage)
        try container.encode(royaltyModulePackage, forKey: .royaltyModulePackage)
        try container.encode(accessRulesPackage, forKey: .accessRulesPackage)
        try container.encode(genesisHelperPackage, forKey: .genesisHelperPackage)
        try container.encode(faucetPackage, forKey: .faucetPackage)
        try container.encode(consensusManager, forKey: .consensusManager)
        try container.encode(genesisHelper, forKey: .genesisHelper)
        try container.encode(faucet, forKey: .faucet)
        try container.encode(poolPackage, forKey: .poolPackage)
    }
}

}
