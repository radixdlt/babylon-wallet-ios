import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionPreviewRequest")
public typealias TransactionPreviewRequest = GatewayAPI.TransactionPreviewRequest

// MARK: - GatewayAPI.TransactionPreviewRequest
extension GatewayAPI {
	public struct TransactionPreviewRequest: Codable, Hashable {
		/** A text-representation of a transaction manifest */
		public private(set) var manifest: String
		/** An array of hex-encoded blob data (optional) */
		public private(set) var blobsHex: [String]?
		/** An integer between `0` and `10^10`, marking the epoch at which the transaction starts being valid */
		public private(set) var startEpochInclusive: Int64
		/** An integer between `0` and `10^10`, marking the epoch at which the transaction is no longer valid */
		public private(set) var endEpochExclusive: Int64
		public private(set) var notaryPublicKey: PublicKey?
		/** Whether the notary should count as a signatory (optional, default false) */
		public private(set) var notaryAsSignatory: Bool?
		/** An integer between `0` and `2^32 - 1`, giving the maximum number of cost units available for transaction execution */
		public private(set) var costUnitLimit: Int64
		/** An integer between `0` and `255`, giving the validator tip as a percentage amount. A value of `1` corresponds to 1% of the fee. */
		public private(set) var tipPercentage: Int
		/** A decimal-string-encoded integer between `0` and `2^64 - 1`, used to ensure the transaction intent is unique. */
		public private(set) var nonce: String
		/** A list of public keys to be used as transaction signers */
		public private(set) var signerPublicKeys: [PublicKey]
		public private(set) var flags: TransactionPreviewRequestFlags

		public init(manifest: String, blobsHex: [String]? = nil, startEpochInclusive: Int64, endEpochExclusive: Int64, notaryPublicKey: PublicKey? = nil, notaryAsSignatory: Bool? = nil, costUnitLimit: Int64, tipPercentage: Int, nonce: String, signerPublicKeys: [PublicKey], flags: TransactionPreviewRequestFlags) {
			self.manifest = manifest
			self.blobsHex = blobsHex
			self.startEpochInclusive = startEpochInclusive
			self.endEpochExclusive = endEpochExclusive
			self.notaryPublicKey = notaryPublicKey
			self.notaryAsSignatory = notaryAsSignatory
			self.costUnitLimit = costUnitLimit
			self.tipPercentage = tipPercentage
			self.nonce = nonce
			self.signerPublicKeys = signerPublicKeys
			self.flags = flags
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case manifest
			case blobsHex = "blobs_hex"
			case startEpochInclusive = "start_epoch_inclusive"
			case endEpochExclusive = "end_epoch_exclusive"
			case notaryPublicKey = "notary_public_key"
			case notaryAsSignatory = "notary_as_signatory"
			case costUnitLimit = "cost_unit_limit"
			case tipPercentage = "tip_percentage"
			case nonce
			case signerPublicKeys = "signer_public_keys"
			case flags
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(manifest, forKey: .manifest)
			try container.encodeIfPresent(blobsHex, forKey: .blobsHex)
			try container.encode(startEpochInclusive, forKey: .startEpochInclusive)
			try container.encode(endEpochExclusive, forKey: .endEpochExclusive)
			try container.encodeIfPresent(notaryPublicKey, forKey: .notaryPublicKey)
			try container.encodeIfPresent(notaryAsSignatory, forKey: .notaryAsSignatory)
			try container.encode(costUnitLimit, forKey: .costUnitLimit)
			try container.encode(tipPercentage, forKey: .tipPercentage)
			try container.encode(nonce, forKey: .nonce)
			try container.encode(signerPublicKeys, forKey: .signerPublicKeys)
			try container.encode(flags, forKey: .flags)
		}
	}
}
