import Foundation

// MARK: - HD.Root
extension HD {
	public struct Root: Sendable, Hashable {
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

extension HD.Root {
	public static let minBitCount = 128
	public static let maxBitCount = 512

	public enum Error: Swift.Error, Equatable {
		case tooFewBits(got: Int, expectedAtLeast: Int)
		case tooManyBits(got: Int, expectedAtMost: Int)
	}
}

extension HD.Root {
	internal func deriveKey<Curve>(
		path: HD.Path.Full,
		keyToDerive: KeyToDerive
	) throws -> HD.ExtendedKey<Curve> {
		try deriveKey(
			path: path,
			curve: Curve.self,
			keyToDerive: keyToDerive
		)
	}

	internal func deriveKey<Curve>(
		path: HD.Path.Full,
		curve: Curve.Type,
		keyToDerive: KeyToDerive
	) throws -> HD.ExtendedKey<Curve> {
		// 1. Calculate I = HMAC-SHA512(Key = Curve, Data = S)
		let hmacKeyData = Curve.curveSeed.data(using: .utf8)!
		if Curve.curveSeed.contains("r1") {
			print(Curve.curveSeed)
			print(Curve.curveSeed)
		}
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

extension HD.Root {
	public func derivePrivateKey<Curve>(path: HD.Path.Full) throws -> HD.ExtendedKey<Curve> {
		try derivePrivateKey(path: path, curve: Curve.self)
	}

	public func derivePrivateKey<Curve>(path: HD.Path.Full, curve: Curve.Type) throws -> HD.ExtendedKey<Curve> {
		try deriveKey(path: path, keyToDerive: .derivePrivateKey)
	}

	public func derivePublicKey<Curve>(path: HD.Path.Full) throws -> HD.ExtendedKey<Curve> {
		try derivePublicKey(path: path, curve: Curve.self)
	}

	public func derivePublicKey<Curve>(path: HD.Path.Full, curve: Curve.Type) throws -> HD.ExtendedKey<Curve> {
		try deriveKey(path: path, keyToDerive: .derivePublicKeyOnly)
	}
}
