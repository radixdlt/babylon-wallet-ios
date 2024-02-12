import Foundation

// MARK: - NotarizedTransaction
public struct NotarizedTransaction: DummySargon {
	public func compile() throws -> Data {
		panic()
	}

	public init(signedIntent: Any, notarySignature: Any) throws {
		panic()
	}

	public static func decompile(compiledNotarizedTransaction: Any) -> Self {
		panic()
	}

	public func signedIntent() -> SignedIntent {
		panic()
	}

	public func notarySignature() -> SLIP10.Signature {
		panic()
	}
}
