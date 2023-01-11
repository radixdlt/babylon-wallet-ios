import Foundation

public struct NotarizedTransaction: Sendable, Codable, Hashable {
	public let signedIntent: SignedTransactionIntent
	public let notarySignature: Engine.Signature

	public init(
		signedIntent: SignedTransactionIntent,
		notarySignature: Engine.Signature
	) {
		self.signedIntent = signedIntent
		self.notarySignature = notarySignature
	}

	private enum CodingKeys: String, CodingKey {
		case signedIntent = "signed_intent"
		case notarySignature = "notary_signature"
	}
}
