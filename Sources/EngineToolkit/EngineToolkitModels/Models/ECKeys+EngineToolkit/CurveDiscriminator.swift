import Foundation

// MARK: - CurveDiscriminator
public enum CurveDiscriminator: String, Sendable, Hashable, Codable {
	case ecdsaSecp256k1 = "EcdsaSecp256k1"
	case eddsaEd25519 = "EddsaEd25519"
}

// MARK: - ECPrimitiveKind
public enum ECPrimitiveKind: String, Sendable, Codable, Hashable {
	case publicKey = "PublicKey"
	case signature = "Signature"
}

extension String {
	public func confirmCurveDiscriminator(curve: CurveDiscriminator, kind: ECPrimitiveKind) throws {
		guard hasSuffix(kind.rawValue) else {
			throw InternalDecodingFailure.curveKeyTypeMismatch(expected: kind, butGot: self)
		}
		let curveString = String(dropLast(kind.rawValue.count))
		guard CurveDiscriminator(rawValue: curveString) == curve else {
			throw InternalDecodingFailure.curveMismatch(expected: curve, butGot: curveString)
		}
	}
}
