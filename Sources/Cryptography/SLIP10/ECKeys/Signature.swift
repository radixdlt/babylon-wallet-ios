import CryptoKit
import Foundation
import K1

// MARK: - SLIP10.Signature
extension SLIP10 {
	public enum Signature: Sendable, Hashable {
		case ecdsaSecp256k1(ECDSASignatureRecoverable)
		case eddsaEd25519(EdDSASignature)
	}
}

extension SLIP10.Signature {
	public func serialize() throws -> Data {
		switch self {
		case let .ecdsaSecp256k1(secp256k1):
			return try secp256k1.radixSerialize()
		case let .eddsaEd25519(curve25519):
			return curve25519
		}
	}
}

extension ECDSASignatureRecoverable {
	/// `v || R || S` instead of `rawRepresentation` which does `R || S || v`
	public func radixSerialize() throws -> Data {
		let (rs, v) = try compact()
		return Data([UInt8(v)] + rs)
	}

	//    public func radixSerialize() throws -> Data {
//
	//            let rs = Data(rawRepresentation.prefix(64))
	//            let v = Data([rawRepresentation[64]])
	//            return v + rs
	//        }
}

extension ECDSASignatureRecoverable {
	/// expects `v || R || S` instead of `rawRepresentation` which is `R || S || v`
	public init(radixFormat: Data) throws {
		guard radixFormat.count == 65 else {
			struct InvalidLength: Swift.Error {}
			throw InvalidLength()
		}
		let v = Int32(radixFormat[0])
		let rs = radixFormat.suffix(64)
		try self.init(compactRepresentation: Data(rs), recoveryID: v)
	}

	//      /// expects `v || R || S` instead of `rawRepresentation` which is `R || S || v`
	//      public init(radixFormat: Data) throws {
	//          guard radixFormat.count == 65 else {
	//              struct InvalidLength: Swift.Error {}
	//              throw InvalidLength()
	//          }
	//          let v = Data([radixFormat[0]])
	//          let rs = Data(radixFormat.suffix(64))
	//          try self.init(rawRepresentation: rs + v)
	//      }
}
