//
// AccountDepositPreValidationRequest.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.AccountDepositPreValidationRequest")
typealias AccountDepositPreValidationRequest = GatewayAPI.AccountDepositPreValidationRequest

extension GatewayAPI {

struct AccountDepositPreValidationRequest: Codable, Hashable {

    /** Bech32m-encoded human readable version of the address. */
    private(set) var accountAddress: String
    private(set) var resourceAddresses: [String]
    private(set) var badge: TransactionAccountDepositPreValidationAuthorizedDepositorBadge?

    init(accountAddress: String, resourceAddresses: [String], badge: TransactionAccountDepositPreValidationAuthorizedDepositorBadge? = nil) {
        self.accountAddress = accountAddress
        self.resourceAddresses = resourceAddresses
        self.badge = badge
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case accountAddress = "account_address"
        case resourceAddresses = "resource_addresses"
        case badge
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accountAddress, forKey: .accountAddress)
        try container.encode(resourceAddresses, forKey: .resourceAddresses)
        try container.encodeIfPresent(badge, forKey: .badge)
    }
}

}
