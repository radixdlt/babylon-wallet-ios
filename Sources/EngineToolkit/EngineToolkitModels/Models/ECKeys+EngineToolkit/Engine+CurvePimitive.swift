import Foundation

extension Engine {
	public typealias EcdsaSecp256k1PublicKey = ECPrimitive<EcdsaSecp256k1Curve, PublicKeyPrimitive>
	public typealias EcdsaSecp256k1Signature = ECPrimitive<EcdsaSecp256k1Curve, SignaturePrimitive>
	public typealias EddsaEd25519PublicKey = ECPrimitive<EddsaEd25519Curve, PublicKeyPrimitive>
	public typealias EddsaEd25519Signature = ECPrimitive<EddsaEd25519Curve, SignaturePrimitive>
}

// MARK: - EllipticCurve
public protocol EllipticCurve {
	static var discriminator: CurveDiscriminator { get }
}

// MARK: - EcdsaSecp256k1Curve
public enum EcdsaSecp256k1Curve: EllipticCurve {
	public static var discriminator: CurveDiscriminator = .ecdsaSecp256k1
}

// MARK: - EddsaEd25519Curve
public enum EddsaEd25519Curve: EllipticCurve {
	public static var discriminator: CurveDiscriminator = .eddsaEd25519
}

// MARK: - CurvePrimitiveKind
public protocol CurvePrimitiveKind {
	static var kind: ECPrimitiveKind { get }
}

// MARK: - PublicKeyPrimitive
public enum PublicKeyPrimitive: CurvePrimitiveKind {
	public static var kind: ECPrimitiveKind = .publicKey
}

// MARK: - SignaturePrimitive
public enum SignaturePrimitive: CurvePrimitiveKind {
	public static var kind: ECPrimitiveKind = .signature
}

// MARK: - Engine.ECPrimitive
extension Engine {
	public struct ECPrimitive<Curve: EllipticCurve, PrimitiveKind: CurvePrimitiveKind>: Sendable, Codable, Hashable {
		// MARK: Stored properties
		public let bytes: [UInt8]

		// MARK: Init
		public init(bytes: [UInt8]) {
			self.bytes = bytes
		}

		public init(hex: String) throws {
			// TODO: Validation of length of array
			try self.init(bytes: [UInt8](hex: hex))
		}

		// MARK: Codable

		public func encode(to encoder: Encoder) throws {
			var container: SingleValueEncodingContainer = encoder.singleValueContainer()
			try container.encode(bytes.hex())
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.singleValueContainer()
			try self.init(hex: container.decode(String.self))
		}
	}
}
