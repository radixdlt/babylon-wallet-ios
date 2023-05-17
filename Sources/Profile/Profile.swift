import Prelude

extension ProfileSnapshot.Version {
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
	/// - 33: Change `FactorInstance` to hold `badge` being an enum `virtual`/`physical` (change from flat to nested representation of FactorSource storage)
	public static let minimum: Self = 33
}

// MARK: - Profile
public struct Profile:
	Sendable,
	Hashable,
	CustomStringConvertible,
	CustomDumpReflectable
{
	/// A version of the Profile Snapshot data format used for compatibility checks.
	public let version: ProfileSnapshot.Version

	/// A locally generated stable identfier of this Profile. Useful for checking if
	/// to Profiles which are inequal based on `Equatable` (content) might be the
	/// semantically the same, based on the ID.
	public let id: ID; public typealias ID = UUID

	/// A description of the device the Profile was first generated on,
	/// typically the wallet app reads a human provided device name
	/// if present and able, and/or a model description of the device e.g:
	/// `"My private phone (iPhone SE (2nd generation))"`
	/// This string can be presented to the user during a recovery flow,
	/// when the profile is restored from backup.
	///
	/// The reason why this is mutable (`var`) instead of immutable `let` is
	/// an implementation detailed on iOS, where reading the device name
	/// and model is `async` but we want to be able to `sync` create the
	/// profile, thus tis property at a later point in time where an async
	/// context is available.
	public var creatingDevice: NonEmptyString

	/// All sources of factors, used for authorization such as spending funds, contains no
	/// secrets.
	public var factorSources: FactorSources

	/// Settings for this profile in the app, contains default security configs
	/// as well as display settings.
	public var appPreferences: AppPreferences

	/// Effectivly **per network**: a list of accounts, personas and connected dApps.
	public var networks: Networks

	public init(
		version: ProfileSnapshot.Version = .minimum,
		id: ID,
		creatingDevice: NonEmptyString,
		factorSources: FactorSources,
		appPreferences: AppPreferences,
		networks: Networks
	) {
		self.version = version
		self.id = id
		self.creatingDevice = creatingDevice
		self.factorSources = factorSources
		self.appPreferences = appPreferences
		self.networks = networks
	}

	public init(
		factorSource: FactorSource,
		creatingDevice: NonEmptyString = "placeholder",
		appPreferences: AppPreferences = .init()
	) {
		@Dependency(\.uuid) var uuid
		self.init(
			id: uuid(),
			creatingDevice: creatingDevice,
			factorSources: .init(factorSource),
			appPreferences: appPreferences,
			networks: .init()
		)
	}
}

// MARK: Codable
@available(*, unavailable)
extension Profile: Codable {
	/* Makes it impossible to make Profile Codable. */
}

extension Profile {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"version": version,
				"factorSources": factorSources,
				"appPreferences": appPreferences,
				"networks": networks,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		"version", \(version),
		"factorSources": \(factorSources),
		"appPreferences": \(appPreferences),
		"networks": \(networks)
		"""
	}
}
