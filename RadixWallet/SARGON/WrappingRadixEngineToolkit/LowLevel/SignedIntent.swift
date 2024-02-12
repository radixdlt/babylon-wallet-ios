import Foundation

// MARK: - SignedIntent
public struct SignedIntent: DummySargon {
	public init(intent: TransactionIntent, intentSignatures: [SignatureWithPublicKey]) {
		sargon()
	}

	public func intent() -> TransactionIntent {
		sargon()
	}

	public func signedIntentHash() -> TransactionHash {
		sargon()
	}
}
