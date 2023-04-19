import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionPreviewRequestFlags")
public typealias TransactionPreviewRequestFlags = GatewayAPI.TransactionPreviewRequestFlags

// MARK: - GatewayAPI.TransactionPreviewRequestFlags
extension GatewayAPI {
	public struct TransactionPreviewRequestFlags: Codable, Hashable {
		public private(set) var unlimitedLoan: Bool
		public private(set) var assumeAllSignatureProofs: Bool
		public private(set) var permitDuplicateIntentHash: Bool
		public private(set) var permitInvalidHeaderEpoch: Bool

		public init(unlimitedLoan: Bool, assumeAllSignatureProofs: Bool, permitDuplicateIntentHash: Bool, permitInvalidHeaderEpoch: Bool) {
			self.unlimitedLoan = unlimitedLoan
			self.assumeAllSignatureProofs = assumeAllSignatureProofs
			self.permitDuplicateIntentHash = permitDuplicateIntentHash
			self.permitInvalidHeaderEpoch = permitInvalidHeaderEpoch
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case unlimitedLoan = "unlimited_loan"
			case assumeAllSignatureProofs = "assume_all_signature_proofs"
			case permitDuplicateIntentHash = "permit_duplicate_intent_hash"
			case permitInvalidHeaderEpoch = "permit_invalid_header_epoch"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(unlimitedLoan, forKey: .unlimitedLoan)
			try container.encode(assumeAllSignatureProofs, forKey: .assumeAllSignatureProofs)
			try container.encode(permitDuplicateIntentHash, forKey: .permitDuplicateIntentHash)
			try container.encode(permitInvalidHeaderEpoch, forKey: .permitInvalidHeaderEpoch)
		}
	}
}
