import Foundation

// MARK: - CurveDiscriminator
public enum CurveDiscriminator: String, Sendable, Hashable, Codable {
	case ecdsaSecp256k1 = "EcdsaSecp256k1"
	case eddsaEd25519 = "EddsaEd25519"
}

// MARK: - CurveKeyType
public enum CurveKeyType: String, Sendable, Codable, Hashable {
	case publicKey = "PublicKey"
	case signature = "Signature"
}

extension String {
	public func confirmCurveDiscriminator(curve: CurveDiscriminator, keyType: CurveKeyType) throws {
		guard hasSuffix(keyType.rawValue) else {
			throw InternalDecodingFailure.curveKeyTypeMismatch(expected: keyType, butGot: self)
		}
		let curveString = String(dropLast(keyType.rawValue.count))
		guard CurveDiscriminator(rawValue: curveString) == curve else {
			throw InternalDecodingFailure.curveMismatch(expected: curve, butGot: curveString)
		}
	}
}
