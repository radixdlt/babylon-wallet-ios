import CryptoKit
import Prelude

public extension Slip10CurveType {
	/// The elliptic curve `P256`, `secp256r1`, `prime256v1` or as SLIP-0010 calls it `Nist256p1`
	static let p256 = Self(
		// For some strange reason SLIP-0010 calls P256 "Nist256p1" instead of
		// either `P256`, `secp256r1` or `prime256v1`. Unfortunate!
		// https://github.com/satoshilabs/slips/blob/master/slip-0010.md#master-key-generation
		slip10CurveID: "Nist256p1 seed",
		curveOrder: BigUInt("FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551", radix: 16)!
	)
}

// MARK: - P256 + Slip10SupportedECCurve
extension P256: Slip10SupportedECCurve {
	public typealias PrivateKey = P256.Signing.PrivateKey
	public typealias PublicKey = P256.Signing.PublicKey
	public static let slip10Curve = Slip10CurveType.p256
}

// MARK: - P256.Signing.PrivateKey + ECPrivateKey
extension P256.Signing.PrivateKey: ECPrivateKey {}

// MARK: - P256.Signing.PublicKey + ECPublicKey
extension P256.Signing.PublicKey: ECPublicKey {
	public init<D>(uncompressedRepresentation: D) throws where D: ContiguousBytes {
		try self.init(rawRepresentation: uncompressedRepresentation)
	}

	public init<Bytes>(compressedRepresentation: Bytes) throws where Bytes: ContiguousBytes {
		try self.init(x963Representation: compressedRepresentation)
	}

	public var compressedRepresentation: Data {
		try! x963Representation()
	}
}

internal extension P256.Signing.PublicKey {
	enum CompressionError: Swift.Error, Equatable {
		case rawRepresentationNot64Bytes
		case x963RoundTripFailedKeysDiffer
	}

	/// Compresses the public key to x963Representation
	func x963Representation() throws -> Data {
		let scalarSize = 32
		guard self.rawRepresentation.count == (2 * scalarSize) else { throw CompressionError.rawRepresentationNot64Bytes }
		let xData = self.rawRepresentation.prefix(scalarSize)
		let yData = self.rawRepresentation.suffix(scalarSize)

		let y = BigUInt(yData)
		let x963Prefix: UInt8 = y.isMultiple(of: 2) ? 0x02 : 0x03

		let x963Representation = Data([x963Prefix] + xData)
		assert(x963Representation.count == 33)

		let fromX963Representation = try Self(x963Representation: x963Representation)

		guard fromX963Representation.rawRepresentation == self.rawRepresentation else {
			throw CompressionError.x963RoundTripFailedKeysDiffer
		}
		return x963Representation
	}
}
