import Prelude

// MARK: - ProfileSnapshot.Header
extension ProfileSnapshot {
	public typealias HeaderList = NonEmpty<IdentifiedArrayOf<Header>>

	public struct Header:
		Sendable,
		Hashable,
		Codable, // Snapshot IS Codable, but `Profile` is not.
		CustomStringConvertible,
		CustomDumpReflectable,
		Identifiable
	{
		/// A description of the device the Profile was first generated on,
		/// typically the wallet app reads a human provided device name
		/// if present and able, and/or a model description of the device e.g:
		/// `"My private phone (iPhone SE (2nd generation))"`
		/// This string can be presented to the user during a recovery flow,
		/// when the profile is restored from backup.
		public let creatingDevice: UsedDeviceInfo

		/// The device on which the profile last used.
		/// **Mutable**: will be updated every time the profile is used on a different device
		public var lastUsedOnDevice: UsedDeviceInfo

		/// A locally generated stable identfier of this Profile. Useful for checking if
		/// to Profiles which are inequal based on `Equatable` (content) might be the
		/// semantically the same, based on the ID.
		public let id: ID

		/// When this profile was first created
		public var creationDate: Date {
			creatingDevice.date
		}

		/// When the profile was last updated, by modifications from the user.
		public var lastModified: Date

		/// The hint about the content held by the profile
		public var contentHint: ContentHint

		/// A version of the Profile Snapshot data format used for compatibility checks.
		public let snapshotVersion: Version

		public init(
			creatingDevice: UsedDeviceInfo,
			lastUsedOnDevice: UsedDeviceInfo,
			id: ID,
			lastModified: Date,
			contentHint: ContentHint,
			snapshotVersion: Version = .minimum
		) {
			self.creatingDevice = creatingDevice
			self.lastUsedOnDevice = lastUsedOnDevice
			self.id = id
			self.lastModified = lastModified
			self.contentHint = contentHint
			self.snapshotVersion = snapshotVersion
		}
	}
}

extension ProfileSnapshot.Header {
	public typealias Version = Tagged<Self, UInt32>
	public typealias ID = UUID

	public struct UsedDeviceInfo:
		Sendable,
		Hashable,
		Codable
	{
		/// `"My private phone (iPhone SE (2nd generation))"`
		public let description: NonEmptyString

		/// To detect if the same Profile is used on two different phones
		public let id: ID; public typealias ID = UUID

		/// Date when the Profile was tied to this device
		public let date: Date

		public init(
			description: NonEmptyString,
			id: ID,
			date: Date
		) {
			self.description = description
			self.id = id
			self.date = date
		}
	}

	public struct ContentHint:
		Sendable,
		Hashable,
		Codable
	{
		public var numberOfAccountsOnAllNetworksInTotal: Int
		public var numberOfPersonasOnAllNetworksInTotal: Int
		public var numberOfNetworks: Int

		public init(
			numberOfAccountsOnAllNetworksInTotal: Int = 0,
			numberOfPersonasOnAllNetworksInTotal: Int = 0,
			numberOfNetworks: Int = 0
		) {
			self.numberOfAccountsOnAllNetworksInTotal = numberOfAccountsOnAllNetworksInTotal
			self.numberOfPersonasOnAllNetworksInTotal = numberOfPersonasOnAllNetworksInTotal
			self.numberOfNetworks = numberOfNetworks
		}
	}
}

extension ProfileSnapshot.Header.Version {
	/// Versioning of the Profile Snapshot data format
	/// other libraries should sync with this, i.e. Kotlin lib.
	///
	/// Changelog:
	/// - 7: Added networkID in Account and Persona
	/// - 8: Changed AuthorizedDapp format
	/// - 9: Personas now use Identity addresses as intended.
	/// - 10: Temp switch default network to Hammunet as RC for Betanet v2
	/// - 11: Switch back default network to Nebunet before Betanet v2 release.
	/// - 12: Added `"id"`
	/// - 13: Reverted unintentially change of `"networks"`
	/// - 14: Reverted `Engine.PublicKey` -> `SLIP10.PublicKey` for entities.
	/// - 15: Add `"creatingDevice"` property
	/// - 16: Add `"gateways"` replacing `"networkAndGateway"`
	/// - 17: Rename `"authorizedDapps"` -> `"authorizedDapps"`
	/// - 18: Add `isCurrencyAmountVisible` to app preferences.
	/// - 19: Add `security` to `appPreferences` (iCloud sync)
	/// - 20: Add `storage` for `device` FactorSource (`nextDerivationIndices`), remove `index`
	/// - 21: Rename `P2PClient` to `P2PLink`.
	/// - 22: Rename `perNetwork` to `networks`
	/// - 23: Replace `SHA256` hash for FactorSource with `Blake2`
	/// - 24: Add `isDeveloperModeEnabled` to AppPreferences.
	/// - 25: Merge two conflicting Profile versions together.
	/// - 26: Change Factor Source Storage codable (remove key "properties"). Remove `storage` for "olympia" `.device` factor sources
	/// - 27: Rename `iCloudProfileSyncEnabled` -> `isCloudProfileSyncEnabled` to be platform agnostic.
	/// - 28: CAP26 update (new KeyType values)
	/// - 29: Change FactorSource, split `hint` into (`label`, `description`) tuple.
	/// - 30: Fix critical bug where identity derivation path was used for account
	/// - 31: Add `ledgerHQHardwareWalletSigningDisplayMode` to appPreferences.display
	/// - 32: rename `genesisFactorInstance` -> `transactionSigning` and add `authSigning`
	/// - 33: Add snapshot `header`
	/// - 34: Change `FactorInstance` to hold `badge` being an enum `virtual`/`physical` (change from flat to nested representation of FactorSource storage)
	/// - 35: Change FactorSource into an enum
	/// - 36: Add `structureConfigurations` to `AppPreferences.Security`
	/// - 37: Change `FactorSourceID` -> enum
	/// - 38: Added `updatedOn` date to `SecurityStructureConfiguration`
	/// - 39: Address format changed with `Birch` update
	/// - 40: Changed Persona data/field format
	/// - 41: Nickname is not optional
	/// - 42: Change counter to not be factor source based.
	/// - 43: Added `mnemonicWordCount` in `hint` in `DeviceFactorSource`
	/// - 44: Added `transaction` setting inside `appPreferences` with `defaultDepositGuarantee` decimal value encoded as String
	/// - 45: Merge of 43 and 44.
	/// - 46: Change default gateway to `zabanet`
	/// - 47: Change default gateway to `rcnetv3`
	public static let minimum: Self = 47
}

extension ProfileSnapshot.Header {
	// MARK: - IncompatibleProfileVersion
	public struct IncompatibleProfileVersion: LocalizedError, Equatable {
		public let decodedVersion: Version
		public let minimumRequiredVersion: Version
		public var errorDescription: String? {
			"\(Self.self): decodedVersion: \(decodedVersion), but Profile requires a minimum version of: \(minimumRequiredVersion)"
		}
	}

	public func validateCompatibility() throws {
		let minimumRequiredVersion: Version = .minimum

		guard snapshotVersion >= minimumRequiredVersion else {
			throw IncompatibleProfileVersion(
				decodedVersion: snapshotVersion,
				minimumRequiredVersion: minimumRequiredVersion
			)
		}
	}

	public func isVersionCompatible() -> Bool {
		do {
			try validateCompatibility()
			return true
		} catch {
			return false
		}
	}
}

extension ProfileSnapshot.Header {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"version": snapshotVersion,
				"creatingDevice": creatingDevice,
				"lastUsedOnDevice": lastUsedOnDevice,
				"creationDate": creationDate,
				"lastModified": lastModified,
				"id": id,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		version: \(snapshotVersion),
		creatingDevice: \(creatingDevice),
		creationDate: \(creationDate),
		lastModified: \(lastModified),
		id: \(id),
		"""
	}
}

extension ProfileSnapshot.Header {
	struct HeaderHolder: Decodable {
		let header: ProfileSnapshot.Header
	}

	public static func fromJSON(
		data: Data,
		jsonDecoder: JSONDecoder = .iso8601
	) throws -> Self {
		let versionHolder = try jsonDecoder.decode(HeaderHolder.self, from: data)
		return versionHolder.header
	}
}
