import Sargon

// MARK: - OlympiaAccountToMigrate
public struct OlympiaAccountToMigrate: Sendable, Hashable, CustomDebugStringConvertible, Identifiable {
	public typealias ID = Secp256k1PublicKey

	public var id: ID { publicKey }

	public let accountType: Olympia.AccountType

	public let publicKey: Secp256k1PublicKey
	public let path: Bip44LikePath

	/// Legacy Olympia address
	public let address: LegacyOlympiaAccountAddress

	public let displayName: NonEmptyString?

	/// the non hardened value of the path
	public let addressIndex: HDPathValue

	public init(
		accountType: Olympia.AccountType,
		publicKey: Secp256k1PublicKey,
		path: Bip44LikePath,
		address: LegacyOlympiaAccountAddress,
		displayName: NonEmptyString?
	) {
		self.addressIndex = path.addressIndex
		self.publicKey = publicKey
		self.path = path
		self.address = address
		self.displayName = displayName
		self.accountType = accountType
	}

	public var debugDescription: String {
		"""
		accountType: \(accountType)
		name: \(displayName ?? "Unknown")
		path: \(path)
		publicKey: \(publicKey.hex)
		"""
	}
}
