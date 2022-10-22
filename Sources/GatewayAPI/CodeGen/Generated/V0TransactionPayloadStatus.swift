//
// V0TransactionPayloadStatus.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

public struct V0TransactionPayloadStatus: Codable, Hashable {

    public enum Status: String, Codable, CaseIterable {
        case committedSuccess = "CommittedSuccess"
        case committedFailure = "CommittedFailure"
        case inMempool = "InMempool"
        case rejected = "Rejected"
    }
    /** The hex-encoded notarized transaction hash. This is also known as the payload hash. This hash is SHA256(SHA256(compiled_notarized_transaction)) */
    public private(set) var payloadHash: String
    /** The status of the transaction payload, as per this node */
    public private(set) var status: Status
    /** An explanation for the error, if failed or rejected */
    public private(set) var errorMessage: String?

    public init(payloadHash: String, status: Status, errorMessage: String? = nil) {
        self.payloadHash = payloadHash
        self.status = status
        self.errorMessage = errorMessage
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case payloadHash = "payload_hash"
        case status
        case errorMessage = "error_message"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(payloadHash, forKey: .payloadHash)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
    }
}

