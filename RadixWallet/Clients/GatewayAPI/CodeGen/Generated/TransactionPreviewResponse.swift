//
// TransactionPreviewResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionPreviewResponse")
public typealias TransactionPreviewResponse = GatewayAPI.TransactionPreviewResponse

extension GatewayAPI {

public struct TransactionPreviewResponse: Codable, Hashable {

    /** Hex-encoded binary blob. */
    public private(set) var encodedReceipt: String
    /** An optional field which is only provided if the `request_radix_engine_toolkit_receipt` flag is set to true when requesting a transaction preview from the API. This receipt is primarily intended for use with the toolkit and may contain information that is already available in the receipt provided in the `receipt` field of this response. A typical client of this API is not expected to use this receipt. The primary clients this receipt is intended for is the Radix wallet or any client that needs to perform execution summaries on their transactions.  */
    public private(set) var radixEngineToolkitReceipt: AnyCodable?
    /** This type is defined in the Core API as `TransactionReceipt`. See the Core API documentation for more details.  */
	public private(set) var receipt: CoreAPI.TransactionReceipt
    public private(set) var resourceChanges: [AnyCodable]
    public private(set) var logs: [TransactionPreviewResponseLogsInner]

	public init(encodedReceipt: String, radixEngineToolkitReceipt: AnyCodable? = nil, receipt: CoreAPI.TransactionReceipt, resourceChanges: [AnyCodable], logs: [TransactionPreviewResponseLogsInner]) {
        self.encodedReceipt = encodedReceipt
        self.radixEngineToolkitReceipt = radixEngineToolkitReceipt
        self.receipt = receipt
        self.resourceChanges = resourceChanges
        self.logs = logs
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case encodedReceipt = "encoded_receipt"
        case radixEngineToolkitReceipt = "radix_engine_toolkit_receipt"
        case receipt
        case resourceChanges = "resource_changes"
        case logs
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(encodedReceipt, forKey: .encodedReceipt)
        try container.encodeIfPresent(radixEngineToolkitReceipt, forKey: .radixEngineToolkitReceipt)
        try container.encode(receipt, forKey: .receipt)
        try container.encode(resourceChanges, forKey: .resourceChanges)
        try container.encode(logs, forKey: .logs)
    }
}

}
