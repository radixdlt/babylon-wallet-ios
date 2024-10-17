import Sargon

// MARK: - OlympiaAccountToMigrate
struct OlympiaAccountToMigrate: Sendable, Hashable, CustomDebugStringConvertible, Identifiable {
	typealias ID = Secp256k1PublicKey

	var id: ID { publicKey }

	let accountType: Olympia.AccountType

	let publicKey: Secp256k1PublicKey
	let path: Bip44LikePath

	/// Legacy Olympia address
	let address: LegacyOlympiaAccountAddress

	let displayName: NonEmptyString?

	/// the non hardened value of the path
	let addressIndex: HDPathValue

	init(
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

	var debugDescription: String {
		"""
		accountType: \(accountType)
		name: \(displayName ?? "Unknown")
		path: \(path)
		publicKey: \(publicKey.hex)
		"""
	}
}
