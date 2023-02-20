import ClientPrelude
import Cryptography
import ProfileModels

// MARK: - UseFactorSourceClient
public struct UseFactorSourceClient: Sendable {
	public var onDeviceHDPublicKey: onDeviceHDPublicKey
}

// MARK: UseFactorSourceClient.onDeviceHDPublicKey
extension UseFactorSourceClient {
	public typealias onDeviceHDPublicKey = @Sendable (OnDeviceHDPublicKeyRequest) throws -> Engine.PublicKey
}

// MARK: - OnDeviceHDPublicKeyRequest
public struct OnDeviceHDPublicKeyRequest: Sendable, Hashable {
	public let hdRoot: HD.Root
	public let derivationPath: DerivationPath
	public let curve: Slip10Curve
	public init(hdRoot: HD.Root, derivationPath: DerivationPath, curve: Slip10Curve) {
		self.hdRoot = hdRoot
		self.derivationPath = derivationPath
		self.curve = curve
	}
}
