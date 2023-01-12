import Cryptography
import Prelude

// MARK: - ProfileSnapshot.Version
public extension ProfileSnapshot {
	typealias Version = Tagged<Self, SemanticVersion>
}

// MARK: - ProfileSnapshot.Version.ProfileVersionHolder
private extension ProfileSnapshot.Version {
	struct ProfileVersionHolder: Decodable {
		// name of property MUST match that of ProfileSnapshot
		let version: ProfileSnapshot.Version
	}
}

public extension ProfileSnapshot.Version {
	static func fromJSON(
		data: Data,
		jsonDecoder: JSONDecoder = .iso8601
	) throws -> Self {
		let versionHolder = try jsonDecoder.decode(ProfileVersionHolder.self, from: data)
		return versionHolder.version
	}
}

// MARK: - IncompatibleProfileVersion
struct IncompatibleProfileVersion: LocalizedError, Equatable {
	public let decodedVersion: ProfileSnapshot.Version
	public let minimumRequiredVersion: ProfileSnapshot.Version
	public var errorDescription: String? {
		"\(Self.self): decodedVersion: \(decodedVersion), but Profile requires a minimum version of: \(minimumRequiredVersion)"
	}
}

public extension ProfileSnapshot {
	static func validateCompatability(
		version: Version
	) throws {
		let minimumRequiredVersion: ProfileSnapshot.Version = .minimum

		guard version >= minimumRequiredVersion else {
			throw IncompatibleProfileVersion(
				decodedVersion: version,
				minimumRequiredVersion: minimumRequiredVersion
			)
		}
		// all good
	}
}

public extension ProfileSnapshot {
	@discardableResult
	static func validateVersionCompatability(
		ofProfileSnapshotJSONData data: Data,
		jsonDecoder: JSONDecoder = .iso8601
	) throws -> Version {
		let decodedVersion = try Version.fromJSON(data: data, jsonDecoder: jsonDecoder)
		try validateCompatability(version: decodedVersion)
		return decodedVersion
	}
}

// MARK: - ProfileSnapshot
public struct ProfileSnapshot:
	Sendable,
	Hashable,
	Codable, // Snapshot IS Codable, but `Profile` is not.
	CustomStringConvertible,
	CustomDumpReflectable
{
	/// A Semantic Versioning of the Profile Snapshot data format used for compatability checks.
	public let version: Version

	/// All sources of factors, used for authorization such as spending funds, contains no
	/// secrets.
	public internal(set) var factorSources: FactorSources

	/// Settings for this profile in the app, contains default security configs
	/// as well as display settings.
	public internal(set) var appPreferences: AppPreferences

	/// Effectivly **per network**: a list of accounts, personas and connected dApps.
	public internal(set) var perNetwork: PerNetwork

	fileprivate init(
		profile: Profile
	) {
		self.version = profile.version
		self.appPreferences = profile.appPreferences
		self.perNetwork = profile.perNetwork
		self.factorSources = profile.factorSources
	}
}

// MARK: Take Snapshot
public extension Profile {
	func snaphot() -> ProfileSnapshot {
		.init(profile: self)
	}
}

public extension Profile {
	init(
		snapshot: ProfileSnapshot
	) throws {
		try ProfileSnapshot.validateCompatability(version: snapshot.version)

		self.init(
			version: snapshot.version,
			factorSources: snapshot.factorSources,
			appPreferences: snapshot.appPreferences,
			perNetwork: snapshot.perNetwork
		)
	}
}

public extension ProfileSnapshot {
	var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"factorSources": factorSources,
				"appPreferences": appPreferences,
				"perNetwork": perNetwork,
			],
			displayStyle: .struct
		)
	}

	var description: String {
		"""
		factorSources: \(factorSources),
		appPreferences: \(appPreferences),
		perNetwork: \(perNetwork),
		"""
	}
}
