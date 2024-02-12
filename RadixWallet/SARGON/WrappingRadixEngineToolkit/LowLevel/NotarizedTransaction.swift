import Foundation

// MARK: - NotarizedTransaction
public struct NotarizedTransaction: DummySargon {
	public func compile() throws -> Data {
		sargon()
	}

	public init(signedIntent: Any, notarySignature: Any) throws {
		sargon()
	}

	public static func decompile(compiledNotarizedTransaction: Any) -> Self {
		sargon()
	}

	public func signedIntent() -> SignedIntent {
		sargon()
	}

	public func notarySignature() -> SLIP10.Signature {
		sargon()
	}
}
