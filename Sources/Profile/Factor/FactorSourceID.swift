import Foundation
import Prelude

// MARK: - FactorSourceID
/// FactorSourceKind concatenated with hash of publicKey, in case of HD it is the Hash of the public key derived
/// using CAP26 derivationPath: m/44'/1022'/365'
public struct FactorSourceID: Sendable, Hashable, CodableViaHexCodable, CustomStringConvertible {
	public enum Error: String, Swift.Error, Hashable {
		case invalidByteCount
	}

	public var factorSourceKind: FactorSourceKind {
		let factorSourceKindRawValue = hexCodable[0]
		guard let factorSourceKind = FactorSourceKind(rawValue: factorSourceKindRawValue) else {
			fatalError("Invalid state, unknown factor source kind, value: \(factorSourceKindRawValue)")
		}
		return factorSourceKind
	}

	/// 33 bytes, consisting of `FactorSourceKind(1) || Hash(32)`
	public let hexCodable: HexCodable

	public init(hexCodable: HexCodable) throws {
		guard hexCodable.data.count == 33 else {
			throw Error.invalidByteCount
		}
		let factorSourceKindRawValue = hexCodable[0]
		guard let _ = FactorSourceKind(rawValue: factorSourceKindRawValue) else {
			throw UnknownFactorSourceKind(unknownValue: factorSourceKindRawValue)
		}
		self.hexCodable = hexCodable
	}

	public init(factorSourceKind: FactorSourceKind, hash: Data) throws {
		guard hash.count == 32 else {
			throw Error.invalidByteCount
		}
		self.hexCodable = .init(data: Data([factorSourceKind.rawValue]) + hash)
	}
}

// MARK: - UnknownFactorSourceKind
struct UnknownFactorSourceKind: Swift.Error {
	public let unknownValue: FactorSourceKind.RawValue
}

extension FactorSourceID {
	public var description: String {
		hexCodable.hex()
	}
}

#if DEBUG
extension FactorSourceID {
	public static let previewValue = Self.preview(.device)
	public static func preview(_ factorSourceKind: FactorSourceKind) -> Self {
		try! Self(factorSourceKind: factorSourceKind, hash: .deadbeef32Bytes)
	}
}
#endif // DEBUG
