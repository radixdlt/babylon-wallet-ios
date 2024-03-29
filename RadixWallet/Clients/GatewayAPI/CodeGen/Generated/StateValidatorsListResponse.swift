//
// StateValidatorsListResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateValidatorsListResponse")
public typealias StateValidatorsListResponse = GatewayAPI.StateValidatorsListResponse

extension GatewayAPI {

public struct StateValidatorsListResponse: Codable, Hashable {

    public private(set) var ledgerState: LedgerState
    public private(set) var validators: ValidatorCollection

    public init(ledgerState: LedgerState, validators: ValidatorCollection) {
        self.ledgerState = ledgerState
        self.validators = validators
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case ledgerState = "ledger_state"
        case validators
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ledgerState, forKey: .ledgerState)
        try container.encode(validators, forKey: .validators)
    }
}

}
