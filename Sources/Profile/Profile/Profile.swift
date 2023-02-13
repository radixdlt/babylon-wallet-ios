import Prelude

extension ProfileSnapshot.Version {
	/// Versioning of the Profile Snapshot data format
	/// other libraries should sync with this, i.e. Kotlin lib.
	///
	/// Changelog:
	/// - 7: Added networkID in Account and Persona
	/// - 8: Changed ConnectedDapp format
	/// - 9: Personas now use Identity addresses as intended.
	public static let minimum: Self = 9
}

// MARK: - Profile
public struct Profile:
	Sendable,
	Hashable,
	CustomStringConvertible,
	CustomDumpReflectable
{
	/// A Semantic Versioning of the Profile Snapshot data format used for compatability checks.
	public let version: ProfileSnapshot.Version

	/// All sources of factors, used for authorization such as spending funds, contains no
	/// secrets.
	public internal(set) var factorSources: FactorSources

	/// Settings for this profile in the app, contains default security configs
	/// as well as display settings.
	public var appPreferences: AppPreferences

	/// Effectivly **per network**: a list of accounts, personas and connected dApps.
	public internal(set) var perNetwork: PerNetwork

	internal init(
		version: ProfileSnapshot.Version = .minimum,
		factorSources: FactorSources,
		appPreferences: AppPreferences,
		perNetwork: PerNetwork
	) {
		self.version = version
		self.factorSources = factorSources
		self.appPreferences = appPreferences
		self.perNetwork = perNetwork
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
