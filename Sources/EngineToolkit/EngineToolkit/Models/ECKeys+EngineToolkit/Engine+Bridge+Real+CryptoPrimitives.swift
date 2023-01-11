import Cryptography
import Prelude

public extension SLIP10.PrivateKey {
	init(engine enginePrivateKey: Engine.PrivateKey) {
		switch enginePrivateKey {
		case let .secp256k1(key):
			self = .secp256k1(key)
		case let .curve25519(key):
			self = .curve25519(key)
		}
	}
}

public extension SLIP10.PrivateKey {
	func intoEngine() throws -> Engine.PrivateKey {
		switch self {
		case let .secp256k1(key): return .secp256k1(key)
		case let .curve25519(key): return .curve25519(key)
		}
	}
}

public extension SLIP10.PublicKey {
	init(engine enginePublicKey: Engine.PublicKey) throws {
		switch enginePublicKey {
		case let .eddsaEd25519(key):
			self = try .eddsaEd25519(Curve25519.Signing.PublicKey(rawRepresentation: key.bytes))
		case let .ecdsaSecp256k1(key):
			self = try .ecdsaSecp256k1(.import(from: key.bytes))
		}
	}
}

public extension SLIP10.PublicKey {
	func intoEngine() throws -> Engine.PublicKey {
		switch self {
		case let .ecdsaSecp256k1(key):
			return try .ecdsaSecp256k1(key.intoEngine())
		case let .eddsaEd25519(key):
			return .eddsaEd25519(Engine.EddsaEd25519PublicKey(bytes: [UInt8](key.rawRepresentation)))
		}
	}
}

public extension K1.PublicKey {
	func intoEngine() throws -> Engine.EcdsaSecp256k1PublicKey {
		try .init(bytes: self.rawRepresentation(format: .compressed))
	}
}

public extension SLIP10.Signature {
	init(engine engineSignature: Engine.Signature) throws {
		switch engineSignature {
		case let .eddsaEd25519(signature):
			// TODO: validate
			self = .eddsaEd25519(Data(signature.bytes))
		case let .ecdsaSecp256k1(signature):
			self = try .ecdsaSecp256k1(.init(rawRepresentation: signature.bytes))
		}
	}
}

public extension SignatureWithPublicKey {
	func intoEngine() throws -> Engine.SignatureWithPublicKey {
		switch self {
		case let .ecdsaSecp256k1(signature, _):
			return .ecdsaSecp256k1(
				signature: .init(bytes: [UInt8](signature.rawRepresentation))
			)
		case let .eddsaEd25519(signature, publicKey):
			return .eddsaEd25519(
				signature: Engine.EddsaEd25519Signature(bytes: [UInt8](signature)),
				publicKey: Engine.EddsaEd25519PublicKey(bytes: [UInt8](publicKey.rawRepresentation))
			)
		}
	}
}
