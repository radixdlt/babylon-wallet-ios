import Foundation
import Prelude

// MARK: - FactorSourceID
/// Double Hash of PublicKey, in case of HD it is the Hash of the public key derived
/// using CAP26 derivationPath: m/44'/1022'/365'
public struct FactorSourceID: Sendable, Hashable, CodableViaHexCodable, CustomStringConvertible {
	public enum Error: String, Swift.Error, Hashable {
		case invalidByteCount
	}

	public let hexCodable: HexCodable

	public init(hexCodable: HexCodable) throws {
		guard hexCodable.data.count == 32 else {
			throw Error.invalidByteCount
		}
		self.hexCodable = hexCodable
	}
}

extension FactorSourceID {
	public var description: String {
		hexCodable.hex()
	}
}
