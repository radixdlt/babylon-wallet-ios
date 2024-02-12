import Foundation

// MARK: - SignedIntent
public struct SignedIntent: DummySargon {
	public init(intent: TransactionIntent, intentSignatures: [Any]) {
		panic()
	}

	public func intent() -> TransactionIntent {
		panic()
	}

	public func intentSignatures() -> [SignatureWithPublicKey] {
		panic()
	}

	public func signedIntentHash() -> TransactionHash {
		panic()
	}
}
