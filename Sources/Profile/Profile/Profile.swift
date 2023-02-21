import Prelude

extension ProfileSnapshot.Version {
	/// Versioning of the Profile Snapshot data format
	/// other libraries should sync with this, i.e. Kotlin lib.
	///
	/// Changelog:
	/// - 7: Added networkID in Account and Persona
	/// - 8: Changed ConnectedDapp format
	/// - 9: Personas now use Identity addresses as intended.
	/// - 10: Temp switch default network to Hammunet as RC for Betanet v2
	/// - 11: Switch back default network to Nebunet before Betanet v2 release.
	/// - 12: Added `id`
	/// - 13: Reverted unintentially change of perNetwork
	public static let minimum: Self = 13
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

	/// All sources of factors, used for authorization such as spending funds, contains no
	/// secrets.
	public internal(set) var factorSources: FactorSources

	/// Settings for this profile in the app, contains default security configs
	/// as well as display settings.
	public var appPreferences: AppPreferences

	/// Effectivly **per network**: a list of accounts, personas and connected dApps.
	public internal(set) var perNetwork: PerNetwork

	public init(
		version: ProfileSnapshot.Version = .minimum,
		id: ID,
		factorSources: FactorSources,
		appPreferences: AppPreferences,
		perNetwork: PerNetwork
	) {
		self.version = version
		self.id = id
		self.factorSources = factorSources
		self.appPreferences = appPreferences
		self.perNetwork = perNetwork
	}

	public init(factorSource: FactorSource) {
		self.init(
			id: .init(),
			factorSources: .init(factorSource),
			appPreferences: .default,
			perNetwork: .init()
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
				"perNetwork": perNetwork,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		"version", \(version),
		"factorSources": \(factorSources),
		"appPreferences": \(appPreferences),
		"perNetwork": \(perNetwork)
		"""
	}
}
