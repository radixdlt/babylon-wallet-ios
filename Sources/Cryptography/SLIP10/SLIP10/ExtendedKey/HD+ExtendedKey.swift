import CryptoKit
import Prelude

// MARK: - HD.ExtendedKey
public extension HD {
	struct ExtendedKey<Curve>: Equatable where Curve: Slip10SupportedECCurve {
		internal let key: Key

		public let derivationPath: HD.Path

		public let chainCode: ChainCode
		public let fingerprint: Fingerprint

		internal init(
			derivationPath: HD.Path,
			key: Key,
			chainCode: ChainCode,
			fingerprint: Fingerprint
		) throws {
			self.derivationPath = derivationPath
			self.chainCode = chainCode
			self.fingerprint = fingerprint
			self.key = key
		}
	}
}

// MARK: - HD.ExtendedKey.Key
internal extension HD.ExtendedKey {
	enum Key: Equatable {
		case privateKey(Curve.PrivateKey)
		case publicKeyOnly(Curve.PublicKey)

		var privateKey: Curve.PrivateKey? {
			switch self {
			case let .privateKey(privateKey):
				return privateKey
			case .publicKeyOnly:
				return nil
			}
		}

		var publicKey: Curve.PublicKey {
			switch self {
			case let .privateKey(privateKey):
				return privateKey.publicKey
			case let .publicKeyOnly(publicKey):
				return publicKey
			}
		}

		var isOnlyPublicKey: Bool {
			switch self {
			case .privateKey:
				return false
			case .publicKeyOnly:
				return true
			}
		}

		static func == (lhs: Self, rhs: Self) -> Bool {
			lhs.publicKey.rawRepresentation == rhs.publicKey.rawRepresentation
		}
	}
}

public extension HD.ExtendedKey {
	var privateKey: Curve.PrivateKey? { key.privateKey }
	var publicKey: Curve.PublicKey { key.publicKey }
}

// MARK: Equatable
public extension HD.ExtendedKey {
	static func == (lhs: Self, rhs: Self) -> Bool {
		guard
			lhs.chainCode == rhs.chainCode,
			lhs.key == rhs.key,
			lhs.fingerprint == rhs.fingerprint
		else {
			return false
		}
		return true
	}
}

internal extension HD.ExtendedKey {
	func keyAsData(forceSelectPublicKey: Bool) -> Data {
		var serializedBytes: Data
		switch (forceSelectPublicKey, key) {
		case (false, let .privateKey(privateKey)):
			serializedBytes = privateKey.rawRepresentation
		case (true, _):
			serializedBytes = self.publicKey.compressedRepresentation
		case let (_, .publicKeyOnly(publicKey)):
			serializedBytes = publicKey.compressedRepresentation
		}

		if serializedBytes.count == 32 {
			serializedBytes.insert(0x00, at: 0)
		}
		assert(serializedBytes.count == 33)
		return serializedBytes
	}

	func keyAsScalar(forceSelectPublicKey: Bool) -> BInt {
		BInt(bytes: keyAsData(forceSelectPublicKey: forceSelectPublicKey).bytes)
	}
}

// MARK: - KeyToDerive
internal enum KeyToDerive: Equatable {
	case derivePublicKeyOnly
	case derivePrivateKey

	var isPublicOnly: Bool {
		switch self {
		case .derivePrivateKey: return false
		case .derivePublicKeyOnly: return true
		}
	}
}

internal func serializeByPrependingByteToReachKeyLength(
	scalar: BInt,
	keyLength targetBytecount: Int = 32,
	prependingByte byteToPrepend: UInt8 = 0x00
) -> Data {
	var bytes = scalar.getBytes().bytes
	while bytes.count < targetBytecount {
		bytes.insert(byteToPrepend, at: 0)
	}

	assert(bytes.count == targetBytecount)
	return Data(bytes)
}

private extension HD.ExtendedKey {
	static func derivePrivateKeyAlways(
		parent: Self,
		component: HD.Path.Component.Child
	) throws -> Self {
		let derivationPath: HD.Path

		switch parent.derivationPath {
		case let .full(parentFullPath):
			derivationPath = try .full(parentFullPath.appending(child: component))
		case let .relative(parentRelativePath):
			derivationPath = try .relative(parentRelativePath.appending(child: component))
		}

		if Curve.isCurve25519 {
			if !component.isHardened {
				throw HD.DerivationError.curve25519RequiresHardenedPath
			}
			if let parentNonRootComponent = parent.derivationPath.components.last?.asChild {
				// if Curve25519, ALL components in a path must be hardened
				assert(parentNonRootComponent.isHardened)
			}
		}

		let ser32i = component.value.data

		let n = Curve.slip10Curve.curveOrder

		let (secretKey, chainCode) = try keyAndChainCode(
			curve: Curve.self,
			hmacKeyData: parent.chainCode.chainCode,
			s: parent.keyAsData(forceSelectPublicKey: !component.isHardened) + ser32i,
			formKey: { ($0 + parent.keyAsScalar(forceSelectPublicKey: false)) % n }
		) { s, _, _, iR in
			// 5. (resulting key is invalid): Data = `0x01 || IR || ser32(i)`
			// and restart at step 2.
			s = Data([0x01]) + iR + ser32i
		}

		let privateKeyBytes = serializeByPrependingByteToReachKeyLength(scalar: secretKey)
		let privateKey = try Curve.PrivateKey(rawRepresentation: privateKeyBytes)
		return try Self(
			derivationPath: derivationPath,
			key: .privateKey(privateKey),
			chainCode: chainCode,
			fingerprint: Fingerprint(publicKey: parent.publicKey)
		)
	}

	static func deriveKey(
		parent: Self,
		relativePath path: HD.Path.Relative,
		keyToDerive: KeyToDerive
	) throws -> Self {
		let children = path.components.compactMap(\.asChild)
		var extendedKey = parent

		for child in children {
			extendedKey = try extendedKey.derivePrivateKey(component: child)
		}

		return try extendedKey.selecting(keyToDerive: keyToDerive)
	}
}

internal extension HD.ExtendedKey {
	func selecting(keyToDerive: KeyToDerive) throws -> Self {
		let key: Key = try {
			switch keyToDerive {
			case .derivePublicKeyOnly:
				return .publicKeyOnly(self.publicKey)
			case .derivePrivateKey:
				guard let presentPrivateKey = self.privateKey else {
					throw Error.cannotDerivePrivateKeyFromPublicKeyOnly
				}
				return .privateKey(presentPrivateKey)
			}
		}()

		return try Self(
			derivationPath: self.derivationPath,
			key: key,
			chainCode: self.chainCode,
			fingerprint: self.fingerprint
		)
	}
}

// MARK: - HD.ExtendedKey.Error
public extension HD.ExtendedKey {
	enum Error: Swift.Error {
		case providedPublicKeyDoesNotMatchThatOfPrivateKey
		case cannotDerivePrivateKeyFromPublicKeyOnly
	}
}

public extension HD.ExtendedKey {
	func derivePrivateKey(
		component: HD.Path.Component.Child
	) throws -> Self {
		try Self.derivePrivateKeyAlways(parent: self, component: component)
	}

	func derivePrivateKey(
		path: HD.Path.Relative
	) throws -> Self {
		try Self.deriveKey(parent: self, relativePath: path, keyToDerive: .derivePrivateKey)
	}

	func derivePublicKey(
		component: HD.Path.Component.Child
	) throws -> Self {
		if key.isOnlyPublicKey, Curve.isCurve25519 {
			throw HD.DerivationError.curve25519LacksPublicParentKeyToPublicChildKeyInSlip10
		}
		return try self.derivePrivateKey(component: component).selecting(keyToDerive: .derivePublicKeyOnly)
	}

	func derivePublicKey(
		path: HD.Path.Relative
	) throws -> Self {
		if key.isOnlyPublicKey, Curve.isCurve25519 {
			throw HD.DerivationError.curve25519LacksPublicParentKeyToPublicChildKeyInSlip10
		}
		return try self.derivePrivateKey(path: path).selecting(keyToDerive: .derivePublicKeyOnly)
	}
}

internal func keyAndChainCode<Curve: Slip10SupportedECCurve>(
	curve: Curve.Type,
	hmacKeyData: Data,
	s: @autoclosure () throws -> Data,
	formKey: (BInt) -> BInt,
	updateS: (_ s: inout Data, _ i: Data, _ iL: BInt, _ iR: Data) -> Void
) throws -> (secretKey: BInt, chainCode: ChainCode) {
	let n = Curve.slip10Curve.curveOrder
	let hmacKey = SymmetricKey(data: hmacKeyData)
	var secretKey: BInt!
	var chainCode = Data()
	var s = try s()

	repeat {
		let i = HMAC<SHA512>.authenticationCode(for: s, using: hmacKey)
		let iData = Data(i)
		let iLData = Data(i.prefix(32))
		let iR = Data(i.suffix(32))

		chainCode = iR
		let iL = BInt(bytes: iLData.bytes)
		if Curve.isCurve25519 {
			secretKey = iL
		} else {
			let keyCandidate = formKey(iL)
			let iL_is_less_than_CurveOrder = iL < n
			let keyCandidateNotZero = keyCandidate != 0
			let isKeyValid = iL_is_less_than_CurveOrder && keyCandidateNotZero

			if isKeyValid {
				secretKey = formKey(iL)
			} else {
				updateS(&s, iData, iL, iR)
			}
		}
	} while secretKey == nil

	return try (secretKey, chainCode: ChainCode(data: chainCode))
}
