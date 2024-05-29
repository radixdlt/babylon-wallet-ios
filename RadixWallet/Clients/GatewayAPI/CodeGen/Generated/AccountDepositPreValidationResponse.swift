//
// AccountDepositPreValidationResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.AccountDepositPreValidationResponse")
public typealias AccountDepositPreValidationResponse = GatewayAPI.AccountDepositPreValidationResponse

extension GatewayAPI {

public struct AccountDepositPreValidationResponse: Codable, Hashable {

    public private(set) var ledgerState: LedgerState
    public private(set) var allowsTryDepositBatch: Bool
    /** The fully resolved try_deposit_* ability of each resource (which takes all the inputs into account, including the authorized depositor badge, the default deposit rule and the resource-specific details). */
    public private(set) var resourceSpecificBehaviour: [AccountDepositPreValidationResourceSpecificBehaviourItem]?
    public private(set) var decidingFactors: AccountDepositPreValidationDecidingFactors

    public init(ledgerState: LedgerState, allowsTryDepositBatch: Bool, resourceSpecificBehaviour: [AccountDepositPreValidationResourceSpecificBehaviourItem]? = nil, decidingFactors: AccountDepositPreValidationDecidingFactors) {
        self.ledgerState = ledgerState
        self.allowsTryDepositBatch = allowsTryDepositBatch
        self.resourceSpecificBehaviour = resourceSpecificBehaviour
        self.decidingFactors = decidingFactors
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case ledgerState = "ledger_state"
        case allowsTryDepositBatch = "allows_try_deposit_batch"
        case resourceSpecificBehaviour = "resource_specific_behaviour"
        case decidingFactors = "deciding_factors"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ledgerState, forKey: .ledgerState)
        try container.encode(allowsTryDepositBatch, forKey: .allowsTryDepositBatch)
        try container.encodeIfPresent(resourceSpecificBehaviour, forKey: .resourceSpecificBehaviour)
        try container.encode(decidingFactors, forKey: .decidingFactors)
    }
}

}
