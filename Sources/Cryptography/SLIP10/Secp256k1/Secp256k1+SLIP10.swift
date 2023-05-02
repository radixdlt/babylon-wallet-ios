import K1
import Prelude

public typealias SECP256K1 = K1

// MARK: - K1 + SLIP10CurveProtocol
extension K1: SLIP10CurveProtocol {
	public static let curve: SLIP10.Curve = .secp256k1
}

// MARK: - K1.PublicKey + ECPublicKey
extension K1.PublicKey: ECPublicKey {
	public var compressedRepresentation: Data {
		try! Data(rawRepresentation(format: .compressed))
	}

	public init<Bytes>(compressedRepresentation pointer: Bytes) throws where Bytes: ContiguousBytes {
		self = try K1.PublicKey.import(from: pointer)
	}

	/// Creates a key from a raw representation.
	public init<D>(rawRepresentation: D) throws where D: ContiguousBytes {
		self = try K1.PublicKey.import(from: rawRepresentation)
	}

	/// A raw representation of the key.
	public var rawRepresentation: Data {
		try! Data(rawRepresentation(format: .compressed)) // hmm use uncompressed here?
	}
}

// MARK: - K1.PrivateKey + ECPrivateKey
extension K1.PrivateKey: ECPrivateKey {
	public typealias PublicKey = K1.PublicKey

	/// Creates a key from a raw representation.
	public init<D>(rawRepresentation data: D) throws where D: ContiguousBytes {
		self = try K1.PrivateKey.import(rawRepresentation: data)
	}
}

// MARK: - K1.PublicKey + CustomDebugStringConvertible
extension K1.PublicKey: CustomDebugStringConvertible {
	public var debugDescription: String {
		compressedRepresentation.hex
	}
}
