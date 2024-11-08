//
// ScryptoSborValue.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.ScryptoSborValue")
typealias ScryptoSborValue = GatewayAPI.ScryptoSborValue

extension GatewayAPI {

struct ScryptoSborValue: Codable, Hashable {

    /** Hex-encoded binary blob. */
    private(set) var rawHex: String
    private(set) var programmaticJson: ProgrammaticScryptoSborValue

    init(rawHex: String, programmaticJson: ProgrammaticScryptoSborValue) {
        self.rawHex = rawHex
        self.programmaticJson = programmaticJson
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case rawHex = "raw_hex"
        case programmaticJson = "programmatic_json"
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rawHex, forKey: .rawHex)
        try container.encode(programmaticJson, forKey: .programmaticJson)
    }
}

}
