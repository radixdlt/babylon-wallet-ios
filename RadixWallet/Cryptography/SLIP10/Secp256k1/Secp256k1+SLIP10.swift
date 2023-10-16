import CryptoKit
public typealias SECP256K1 = K1

// MARK: - K1 + SLIP10CurveProtocol
extension K1: SLIP10CurveProtocol {
	public typealias PrivateKey = K1.ECDSAWithKeyRecovery.PrivateKey

	public typealias PublicKey = K1.ECDSAWithKeyRecovery.PublicKey

	public static let curve: SLIP10.Curve = .secp256k1
}

// MARK: - K1.ECDSAWithKeyRecovery.PublicKey + ECPublicKey
extension K1.ECDSAWithKeyRecovery.PublicKey: ECPublicKey {}

// MARK: - K1.ECDSAWithKeyRecovery.PrivateKey + ECPrivateKey
extension K1.ECDSAWithKeyRecovery.PrivateKey: ECPrivateKey {}

// MARK: - K1.ECDSAWithKeyRecovery.PublicKey + CustomDebugStringConvertible
extension K1.ECDSAWithKeyRecovery.PublicKey: CustomDebugStringConvertible {
	public var debugDescription: String {
		compressedRepresentation.hex
	}
}
