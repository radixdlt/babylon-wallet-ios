import Foundation

// MARK: - NotarizedTransaction
public struct NotarizedTransaction: DummySargon {
	public func compile() throws -> Data {
		sargon()
	}

	public init(signedIntent: SignedIntent, notarySignature: SLIP10.Signature) throws {
		sargon()
	}
}
