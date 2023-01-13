import Prelude

// MARK: From String
public extension HD.ExtendedKey {
	enum Version: UInt32 {
		case mainnetPublic = 0x0488_B21E
		case mainnetPrivate = 0x0488_ADE4
		case testnetPublic = 0x0435_87CF
		case testnetPrivate = 0x0435_8394

		var isPublic: Bool {
			switch self {
			case .mainnetPublic, .testnetPublic: return true
			case .mainnetPrivate, .testnetPrivate: return false
			}
		}

		var isPrivate: Bool {
			switch self {
			case .mainnetPublic, .testnetPublic: return false
			case .mainnetPrivate, .testnetPrivate: return true
			}
		}
	}

	func xpub(mainnet: Bool = true) throws -> String {
		let version = mainnet ? Version.mainnetPublic : .testnetPublic
		return try serialize(version: version)
	}

	func xprv(mainnet: Bool = true) throws -> String {
		let version = mainnet ? Version.mainnetPrivate : .testnetPrivate
		return try serialize(version: version)
	}

	init(string: String) throws {
		guard let contents = Base58Check.decode(string) else {
			throw DeserializationError.failedToBase58Decode
		}
		guard contents.count == serializedByteCount else {
			throw DeserializationError.base58DecodedHasIncorrectLength
		}

		let dataReader = DataReader(data: contents)

		let version = try dataReader.read(Version.self)
		let depth = try dataReader.readByte()
		let fingerprint = try Fingerprint(data: dataReader.read(byteCount: 4))
		let childNumber: HD.Path.Component.Child.Value = try dataReader.readUInt32()
		let chainCode = try ChainCode(
			data: dataReader.read(byteCount: ChainCode.byteCount)
		)
		var keyData = try dataReader.read(byteCount: 33)
		assert(dataReader.isFinished)
		if version.isPrivate || (version.isPublic && Curve.isCurve25519) {
			keyData = Data(keyData.dropFirst())
		}

		let pathComponent = HD.Path.Component.Child(depth: depth, value: childNumber)
		let derivationPath: HD.Path = try .relative(.init(components: [.child(pathComponent)]))

		let key: Key = try {
			if version.isPublic {
				let publicKey = try Curve.PublicKey(compressedRepresentation: keyData)
				return .publicKeyOnly(publicKey)
			} else {
				let privateKey = try Curve.PrivateKey(rawRepresentation: keyData)
				return .privateKey(privateKey)
			}
		}()

		try self.init(
			derivationPath: derivationPath,
			key: key,
			chainCode: chainCode,
			fingerprint: fingerprint
		)
	}
}

private let serializedByteCount = 78

// MARK: - HD.ExtendedKey.DeserializationError
public extension HD.ExtendedKey {
	enum DeserializationError: Swift.Error, Equatable {
		case failedToBase58Decode
		case base58DecodedHasIncorrectLength
	}
}

// MARK: - HD.ExtendedKey.SerializationError
public extension HD.ExtendedKey {
	enum SerializationError: Swift.Error, Equatable {
		/// Not possible even in BIP32
		case privateKeyNotPresent
	}
}

private extension HD.ExtendedKey {
	func serialize(version: Version) throws -> String {
		if version.isPrivate, self.key.isOnlyPublicKey {
			throw SerializationError.privateKeyNotPresent
		}
		let versionData: Data = version.rawValue.data

		let depth = self.derivationPath.depth

		let depthData = try depth().data
		assert(depthData.count == 1)

		let childNumber: HD.Path.Component.Child.Value = self.derivationPath.components.last?.asChild?.value ?? 0
		let childNumberData = childNumber.data
		assert(childNumberData.count == 4)

		let keyData = self.keyAsData(forceSelectPublicKey: version.isPublic)
		assert(keyData.count == 33)

		let input: Data =
			versionData +
			depthData +
			self.fingerprint.fingerprint +
			childNumberData +
			self.chainCode.chainCode +
			keyData

		assert(input.count == serializedByteCount)
		return Base58Check.encode(input)
	}
}
