import Foundation

extension SLIP10.PublicKey {
	public var bytes: Data {
		switch self {
		case let .ecdsaSecp256k1(key):
			key.compressedRepresentation
		case let .eddsaEd25519(key):
			key.rawRepresentation
		}
	}
}
