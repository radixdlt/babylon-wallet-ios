//
// TransactionPreviewOptIns.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionPreviewOptIns")
typealias TransactionPreviewOptIns = GatewayAPI.TransactionPreviewOptIns

extension GatewayAPI {

/** A set of flags to configure the response of the transaction preview. */
struct TransactionPreviewOptIns: Codable, Hashable {

    /** This flag controls whether the preview response will include a Radix Engine Toolkit serializable receipt or not. If not provided, this defaults to `false` and no toolkit receipt is provided in the response.  */
    private(set) var radixEngineToolkitReceipt: Bool? = false

    init(radixEngineToolkitReceipt: Bool? = false) {
        self.radixEngineToolkitReceipt = radixEngineToolkitReceipt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case radixEngineToolkitReceipt = "radix_engine_toolkit_receipt"
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(radixEngineToolkitReceipt, forKey: .radixEngineToolkitReceipt)
    }
}

}
