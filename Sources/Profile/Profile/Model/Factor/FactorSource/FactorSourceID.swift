import Bite
import CryptoKit
import EngineToolkit
import Foundation
import SLIP10
import Tagged

/// An identifier for some factor source, it **MUST** be a a stable and unique identifer.
public typealias FactorSourceID = Tagged<FactorSource, HexCodable>
public extension FactorSourceID {
	init(hashingPublicKey publicKeyData: Data) {
		self.init(
			rawValue: HexCodable(
				data: SHA256.hash(publicKey: publicKeyData)
			)
		)
	}
}

public extension HD.Root {
	func factorSourceID<Curve: Slip10SupportedECCurve>(
		curve: Curve.Type
	) throws -> FactorSourceID {
		try SHA256.factorSourceID(hdRoot: self, curve: curve)
	}
}

public extension SHA256 {
	/// `SHA256(SHA256(publicKey.compressedForm)`
	fileprivate static func hash(publicKey: Data) -> Data {
		Data(SHA256.twice(data: publicKey))
	}

	/// Creates a FactorSourceID using `SHA256(SHA256(hdRoot.GETID.publicKey.compressedForm)` of the `masterKey`
	static func factorSourceID<Curve: Slip10SupportedECCurve>(
		getIDKey: HD.ExtendedKey<Curve>
	) -> FactorSourceID {
		FactorSourceID(
			hashingPublicKey: getIDKey.publicKey.compressedRepresentation
		)
	}

	/// Creates a FactorSourceID using `SHA256(SHA256(hdRoot.GETID.publicKey.compressedForm)`
	/// where `"GETID"` is derivation path, according to [CAP-26][cap26]
	///
	/// [cap26]: https://radixdlt.atlassian.net/l/cp/UNaBAGUC
	static func factorSourceID<Curve: Slip10SupportedECCurve>(
		hdRoot: HD.Root,
		curve: Curve.Type
	) throws -> FactorSourceID {
		let getIDKey = try hdRoot.derivePrivateKey(path: .getID, curve: curve)
		return Self.factorSourceID(getIDKey: getIDKey)
	}

	/// Creates a `FactorInstanceID` using `SHA256(SHA256(publicKey.compressedForm)` of the `publickey`
	static func factorInstanceID(publicKey: PublicKey) -> FactorInstanceID {
		FactorInstanceID(
			rawValue: HexCodable(
				data: Self.hash(publicKey: publicKey.compressedData)
			)
		)
	}
}

import CustomDump

// MARK: - Tagged + CustomDumpStringConvertible
extension Tagged: CustomDumpStringConvertible where Self.RawValue: CustomDumpStringConvertible {
	public var customDumpDescription: String {
		self.rawValue.customDumpDescription
	}
}

// MARK: - Tagged + CustomDumpReflectable
extension Tagged: CustomDumpReflectable where Self.RawValue: CustomDumpReflectable {
	public var customDumpMirror: Mirror {
		self.rawValue.customDumpMirror
	}
}

// MARK: - Tagged + CustomDumpRepresentable
extension Tagged: CustomDumpRepresentable where Self.RawValue: CustomDumpRepresentable {
	public var customDumpValue: Any {
		self.rawValue.customDumpValue
	}
}
