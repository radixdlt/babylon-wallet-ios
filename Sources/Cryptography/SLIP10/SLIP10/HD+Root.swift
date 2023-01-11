import Foundation

// MARK: - HD.Root
public extension HD {
	struct Root {
		public let seed: Data

		/// Initialize HD Root with 128-512 bits. 256 bits is recommended.
		public init(seed: Data) throws {
			let bitCount = seed.count * 8
			if bitCount < Self.minBitCount {
				throw Error.tooFewBits(got: bitCount, expectedAtLeast: Self.minBitCount)
			}
			if bitCount > Self.maxBitCount {
				throw Error.tooManyBits(got: bitCount, expectedAtMost: Self.maxBitCount)
			}
			self.seed = seed
		}
	}
}

public extension HD.Root {
	static let minBitCount = 128
	static let maxBitCount = 512

	enum Error: Swift.Error, Equatable {
		case tooFewBits(got: Int, expectedAtLeast: Int)
		case tooManyBits(got: Int, expectedAtMost: Int)
	}
}

internal extension HD.Root {
	func deriveKey<Curve>(
		path: HD.Path.Full,
		keyToDerive: KeyToDerive
	) throws -> HD.ExtendedKey<Curve> {
		try deriveKey(
			path: path,
			curve: Curve.self,
			keyToDerive: keyToDerive
		)
	}

	func deriveKey<Curve>(
		path: HD.Path.Full,
		curve: Curve.Type,
		keyToDerive: KeyToDerive
	) throws -> HD.ExtendedKey<Curve> {
		// 1. Calculate I = HMAC-SHA512(Key = Curve, Data = S)
		let hmacKeyData = Curve.slip10Curve.slip10CurveID.data(using: .utf8)!
		let hmacDataS = self.seed

		let (secretKey, chainCode) = try keyAndChainCode(
			curve: Curve.self,
			hmacKeyData: hmacKeyData,
			s: hmacDataS,
			formKey: { $0 }
		) { s, i, _, _ in
			// 	Set S := I
			s = i
		}

		let masterPrivateKeyBytes = serializeByPrependingByteToReachKeyLength(scalar: secretKey)
		let masterPrivateKey = try Curve.PrivateKey(rawRepresentation: masterPrivateKeyBytes)

		// 3. Use parse256(IL) as master secret key, and IR as master chain code.
		let masterKey: HD.ExtendedKey<Curve> = try .init(
			derivationPath: .full(.root(onlyPublic: path.onlyPublic)),
			key: path.onlyPublic ? .publicKeyOnly(masterPrivateKey.publicKey) : .privateKey(masterPrivateKey),
			chainCode: chainCode,
			fingerprint: .masterKey
		)

		guard let pathRelativeRoot = path.relativeRoot else {
			return masterKey // no more components to derive
		}

		return try masterKey.derivePrivateKey(path: pathRelativeRoot).selecting(keyToDerive: keyToDerive)
	}
}

public extension HD.Root {
	func derivePrivateKey<Curve>(path: HD.Path.Full) throws -> HD.ExtendedKey<Curve> {
		try derivePrivateKey(path: path, curve: Curve.self)
	}

	func derivePrivateKey<Curve>(path: HD.Path.Full, curve: Curve.Type) throws -> HD.ExtendedKey<Curve> {
		try deriveKey(path: path, keyToDerive: .derivePrivateKey)
	}

	func derivePublicKey<Curve>(path: HD.Path.Full) throws -> HD.ExtendedKey<Curve> {
		try derivePublicKey(path: path, curve: Curve.self)
	}

	func derivePublicKey<Curve>(path: HD.Path.Full, curve: Curve.Type) throws -> HD.ExtendedKey<Curve> {
		try deriveKey(path: path, keyToDerive: .derivePublicKeyOnly)
	}
}
