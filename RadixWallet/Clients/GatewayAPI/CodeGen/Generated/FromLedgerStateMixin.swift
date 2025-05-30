//
// FromLedgerStateMixin.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.FromLedgerStateMixin")
typealias FromLedgerStateMixin = GatewayAPI.FromLedgerStateMixin

extension GatewayAPI {

/** defines lower boundary (inclusive) for queried data. i.e &#x60;{ \&quot;from_state_version\&quot; &#x3D; {\&quot;epoch\&quot; &#x3D; 10} }&#x60;, will return data from epoch 10 till current max ledger tip. */
struct FromLedgerStateMixin: Codable, Hashable {

    private(set) var fromLedgerState: LedgerStateSelector?

    init(fromLedgerState: LedgerStateSelector? = nil) {
        self.fromLedgerState = fromLedgerState
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case fromLedgerState = "from_ledger_state"
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(fromLedgerState, forKey: .fromLedgerState)
    }
}

}
