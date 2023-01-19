import K1
import Prelude

public extension Slip10CurveType {
	static let secp256k1 = Self(
		slip10CurveID: "Bitcoin seed",
		curveOrder: BigUInt("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141", radix: 16)!
	)
}

public typealias SECP256K1 = K1

// MARK: - K1 + Slip10SupportedECCurve
extension K1: Slip10SupportedECCurve {
	public typealias PrivateKey = K1.PrivateKey
	public typealias PublicKey = K1.PublicKey
	public static let slip10Curve = Slip10CurveType.secp256k1
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
	public init<D>(uncompressedRepresentation pointer: D) throws where D: ContiguousBytes {
		self = try K1.PublicKey.import(from: pointer)
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
