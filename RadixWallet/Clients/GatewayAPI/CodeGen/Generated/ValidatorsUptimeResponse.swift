//
// ValidatorsUptimeResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.ValidatorsUptimeResponse")
typealias ValidatorsUptimeResponse = GatewayAPI.ValidatorsUptimeResponse

extension GatewayAPI {

struct ValidatorsUptimeResponse: Codable, Hashable {

    private(set) var ledgerState: LedgerState
    private(set) var validators: ValidatorUptimeCollection

    init(ledgerState: LedgerState, validators: ValidatorUptimeCollection) {
        self.ledgerState = ledgerState
        self.validators = validators
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case ledgerState = "ledger_state"
        case validators
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ledgerState, forKey: .ledgerState)
        try container.encode(validators, forKey: .validators)
    }
}

}
