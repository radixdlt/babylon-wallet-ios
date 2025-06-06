//
// AccountDepositPreValidationDecidingFactors.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.AccountDepositPreValidationDecidingFactors")
typealias AccountDepositPreValidationDecidingFactors = GatewayAPI.AccountDepositPreValidationDecidingFactors

extension GatewayAPI {

/** Deciding factors used to calculate response. */
struct AccountDepositPreValidationDecidingFactors: Codable, Hashable {

    /** Whether the input badge belongs to the account's set of authorized depositors. This field will only be present if any badge was passed in the request. */
    private(set) var isBadgeAuthorizedDepositor: Bool?
    private(set) var defaultDepositRule: AccountDefaultDepositRule
    /** Returns deciding factors for each resource. Contains only information about resources presented in the request, not all resource preference rules for queried account. */
    private(set) var resourceSpecificDetails: [AccountDepositPreValidationDecidingFactorsResourceSpecificDetailsItem]?

    init(isBadgeAuthorizedDepositor: Bool? = nil, defaultDepositRule: AccountDefaultDepositRule, resourceSpecificDetails: [AccountDepositPreValidationDecidingFactorsResourceSpecificDetailsItem]? = nil) {
        self.isBadgeAuthorizedDepositor = isBadgeAuthorizedDepositor
        self.defaultDepositRule = defaultDepositRule
        self.resourceSpecificDetails = resourceSpecificDetails
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case isBadgeAuthorizedDepositor = "is_badge_authorized_depositor"
        case defaultDepositRule = "default_deposit_rule"
        case resourceSpecificDetails = "resource_specific_details"
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(isBadgeAuthorizedDepositor, forKey: .isBadgeAuthorizedDepositor)
        try container.encode(defaultDepositRule, forKey: .defaultDepositRule)
        try container.encodeIfPresent(resourceSpecificDetails, forKey: .resourceSpecificDetails)
    }
}

}
