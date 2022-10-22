//
// TransactionPreviewRequest.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

public struct TransactionPreviewRequest: Codable, Hashable {

    /** The logical name of the network */
    public private(set) var network: String
    /** A text-representation of a transaction manifest */
    public private(set) var manifest: String
    /** An array of hex-encoded blob data (optional) */
    public private(set) var blobsHex: [String]?
    /** An integer between 0 and 2^32 - 1, giving the maximum number of cost units available for transaction execution */
    public private(set) var costUnitLimit: Int64
    /** An integer between 0 and 2^32 - 1, specifying the validator tip as a percentage amount. A value of \"1\" corresponds to 1% of the fee. */
    public private(set) var tipPercentage: Int64
    /** A decimal-string-encoded integer between 0 and 2^64-1, used to ensure the transaction intent is unique. */
    public private(set) var nonce: String
    /** A list of public keys to be used as transaction signers */
    public private(set) var signerPublicKeys: [PublicKey]
    public private(set) var flags: TransactionPreviewRequestFlags

    public init(network: String, manifest: String, blobsHex: [String]? = nil, costUnitLimit: Int64, tipPercentage: Int64, nonce: String, signerPublicKeys: [PublicKey], flags: TransactionPreviewRequestFlags) {
        self.network = network
        self.manifest = manifest
        self.blobsHex = blobsHex
        self.costUnitLimit = costUnitLimit
        self.tipPercentage = tipPercentage
        self.nonce = nonce
        self.signerPublicKeys = signerPublicKeys
        self.flags = flags
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case network
        case manifest
        case blobsHex = "blobs_hex"
        case costUnitLimit = "cost_unit_limit"
        case tipPercentage = "tip_percentage"
        case nonce
        case signerPublicKeys = "signer_public_keys"
        case flags
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(network, forKey: .network)
        try container.encode(manifest, forKey: .manifest)
        try container.encodeIfPresent(blobsHex, forKey: .blobsHex)
        try container.encode(costUnitLimit, forKey: .costUnitLimit)
        try container.encode(tipPercentage, forKey: .tipPercentage)
        try container.encode(nonce, forKey: .nonce)
        try container.encode(signerPublicKeys, forKey: .signerPublicKeys)
        try container.encode(flags, forKey: .flags)
    }
}

