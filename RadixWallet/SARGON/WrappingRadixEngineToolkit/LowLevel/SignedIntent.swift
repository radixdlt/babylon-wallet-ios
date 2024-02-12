import Foundation

// MARK: - SignedIntent
public struct SignedIntent: DummySargon {
	public init(intent: TransactionIntent, intentSignatures: [Any]) {
		sargon()
	}

	public func intent() -> TransactionIntent {
		sargon()
	}

	public func intentSignatures() -> [SignatureWithPublicKey] {
		sargon()
	}

	public func signedIntentHash() -> TransactionHash {
		sargon()
	}
}
