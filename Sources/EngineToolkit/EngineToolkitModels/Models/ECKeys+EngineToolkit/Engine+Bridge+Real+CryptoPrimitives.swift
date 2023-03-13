import Cryptography
import Prelude

extension SLIP10.PrivateKey {
	public init(engine enginePrivateKey: Engine.PrivateKey) {
		switch enginePrivateKey {
		case let .secp256k1(key):
			self = .secp256k1(key)
		case let .curve25519(key):
			self = .curve25519(key)
		}
	}
}

extension SLIP10.PrivateKey {
	public func intoEngine() throws -> Engine.PrivateKey {
		switch self {
		case let .secp256k1(key): return .secp256k1(key)
		case let .curve25519(key): return .curve25519(key)
		}
	}
}

extension SLIP10.PublicKey {
	public init(engine enginePublicKey: Engine.PublicKey) throws {
		switch enginePublicKey {
		case let .eddsaEd25519(key):
			self = try .eddsaEd25519(Curve25519.Signing.PublicKey(rawRepresentation: key.bytes))
		case let .ecdsaSecp256k1(key):
			self = try .ecdsaSecp256k1(.import(from: key.bytes))
		}
	}
}

extension SLIP10.PublicKey {
	public func intoEngine() throws -> Engine.PublicKey {
		switch self {
		case let .ecdsaSecp256k1(key):
			return try .ecdsaSecp256k1(key.intoEngine())
		case let .eddsaEd25519(key):
			return .eddsaEd25519(.init(bytes: [UInt8](key.rawRepresentation)))
		}
	}
}

extension K1.PublicKey {
	// NOTE: Here we're not capturing the fact that this is a EcdsaSecp256k1PublicKey
	public func intoEngine() throws -> Engine.ECPrimitive {
		try .init(bytes: self.rawRepresentation(format: .compressed))
	}
}

extension SLIP10.Signature {
	public init(engine engineSignature: Engine.Signature) throws {
		switch engineSignature {
		case let .eddsaEd25519(signature):
			// TODO: validate
			self = .eddsaEd25519(Data(signature.bytes))
		case let .ecdsaSecp256k1(signature):
			self = try .ecdsaSecp256k1(.init(radixFormat: Data(signature.bytes)))
		}
	}
}

extension SignatureWithPublicKey {
	public func intoEngine() throws -> Engine.SignatureWithPublicKey {
		switch self {
		case let .ecdsaSecp256k1(signature, _):
			return try .ecdsaSecp256k1(
				signature: .init(bytes: [UInt8](signature.radixSerialize()))
			)
		case let .eddsaEd25519(signature, publicKey):
			return .eddsaEd25519(
				signature: .init(bytes: [UInt8](signature)),
				publicKey: .init(bytes: [UInt8](publicKey.rawRepresentation))
			)
		}
	}
}
