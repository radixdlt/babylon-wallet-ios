import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - ProfileSnapshot
public struct ProfileSnapshot:
	Sendable,
	Hashable,
	Codable, // Snapshot IS Codable, but `Profile` is not.
	CustomStringConvertible,
	CustomDumpReflectable
{
	public var version: Header.Version {
		header.snapshotVersion
	}

	public let header: Header

	/// All sources of factors, used for authorization such as spending funds, contains no
	/// secrets.
	public let factorSources: FactorSources

	/// Settings for this profile in the app, contains default security configs
	/// as well as display settings.
	public let appPreferences: AppPreferences

	/// Effectivly **per network**: a list of accounts, personas and connected dApps.
	public let networks: Profile.Networks

	fileprivate init(
		profile: Profile
	) {
		self.header = profile.header
		self.appPreferences = profile.appPreferences
		self.networks = profile.networks
		self.factorSources = profile.factorSources
	}
}

// MARK: Take Snapshot
extension Profile {
	public func snapshot() -> ProfileSnapshot {
		.init(profile: self)
	}
}

extension Profile {
	public init(
		snapshot: ProfileSnapshot
	) throws {
		// TODO: Validate compatibility
		self.init(
			header: snapshot.header,
			factorSources: snapshot.factorSources,
			appPreferences: snapshot.appPreferences,
			networks: snapshot.networks
		)
	}
}

extension ProfileSnapshot {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"factorSources": factorSources,
				"appPreferences": appPreferences,
				"networks": networks,
				"header": header.customDumpMirror,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		factorSources: \(factorSources),
		              header: \(header.description),
		appPreferences: \(appPreferences),
		networks: \(networks),
		"""
	}
}
