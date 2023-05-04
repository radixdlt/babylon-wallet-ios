import Prelude

// MARK: - ProfileSnapshot.Header
extension ProfileSnapshot {
	public struct Header:
		Sendable,
		Hashable,
		Codable, // Snapshot IS Codable, but `Profile` is not.
		CustomStringConvertible,
		CustomDumpReflectable
	{
		public typealias Version = Tagged<Self, UInt32>

		/// A description of the device the Profile was first generated on,
		/// typically the wallet app reads a human provided device name
		/// if present and able, and/or a model description of the device e.g:
		/// `"My private phone (iPhone SE (2nd generation))"`
		/// This string can be presented to the user during a recovery flow,
		/// when the profile is restored from backup.
		public let creatingDevice: NonEmptyString

		/// A locally generated stable identfier of this Profile. Useful for checking if
		/// to Profiles which are inequal based on `Equatable` (content) might be the
		/// semantically the same, based on the ID.
		public let id: ID; public typealias ID = UUID

		/// When this profile was first created
		public let creationDate: Date

		/// When the profile was last updated, by modifications from the user
		public let lastModified: Date

		/// A version of the Profile Snapshot data format used for compatibility checks.
		public let snapshotVersion: Version

		public init(
			creatingDevice: NonEmptyString,
			id: ProfileSnapshot.Header.ID,
			creationDate: Date,
			lastModified: Date,
			snapshotVersion: Version = .minimum
		) {
			self.creatingDevice = creatingDevice
			self.id = id
			self.creationDate = creationDate
			self.lastModified = lastModified
			self.snapshotVersion = snapshotVersion
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
	public static let minimum: Self = 30
}

extension ProfileSnapshot.Header {
	// MARK: - IncompatibleProfileVersion
	struct IncompatibleProfileVersion: LocalizedError, Equatable {
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
}

extension ProfileSnapshot.Header {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"version": snapshotVersion,
				"creatingDevice": creatingDevice,
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
