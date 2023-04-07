import Cryptography
import Prelude

// MARK: - OlympiaAccountToMigrate
public struct OlympiaAccountToMigrate: Sendable, Hashable, CustomDebugStringConvertible, Identifiable {
	public typealias ID = K1.PublicKey

	public var id: ID { publicKey }

	public let accountType: LegacyOlympiaAccountType

	public let publicKey: K1.PublicKey
	public let path: LegacyOlympiaBIP44LikeDerivationPath

	/// Legacy Olympia address
	public let address: LegacyOlympiaAccountAddress

	public let displayName: NonEmptyString?

	/// the non hardened value of the path
	public let addressIndex: HD.Path.Component.Child.Value

	public init(
		accountType: LegacyOlympiaAccountType,
		publicKey: K1.PublicKey,
		path: LegacyOlympiaBIP44LikeDerivationPath,
		address: LegacyOlympiaAccountAddress,
		displayName: NonEmptyString?
	) throws {
		/// the non hardened value of the path
		guard let addressIndex = path.fullPath.components.last?.asChild?.nonHardenedValue else {
			assertionFailure("bad path")
			throw ExpectedBIP44LikeDerivationPathToAlwaysContainAddressIndex()
		}
		self.addressIndex = addressIndex
		self.publicKey = publicKey
		self.path = path
		self.address = address
		self.displayName = displayName
		self.accountType = accountType
	}

	public var debugDescription: String {
		"""
		accountType: \(accountType)
		name: \(displayName ?? "")
		path: \(path.derivationPath)
		publicKey: \(publicKey.compressedRepresentation.hex)
		"""
	}
}
