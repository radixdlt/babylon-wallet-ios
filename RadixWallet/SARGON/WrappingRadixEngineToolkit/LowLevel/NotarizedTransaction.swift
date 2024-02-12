import Foundation

// MARK: - NotarizedTransaction
public struct NotarizedTransaction: DummySargon {
	public init(
		signedIntent: SignedIntent,
		notarySignature: SLIP10.Signature
	) throws {
		sargon()
	}

	public func compile() throws -> Data {
		sargon()
	}
}
