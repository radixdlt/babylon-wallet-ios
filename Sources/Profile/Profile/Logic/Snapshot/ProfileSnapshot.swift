import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - ProfileSnapshot.Version
extension ProfileSnapshot {
	public typealias Version = Tagged<Self, UInt32>
}

// MARK: - ProfileSnapshot.Version.ProfileVersionHolder
extension ProfileSnapshot.Version {
	fileprivate struct ProfileVersionHolder: Decodable {
		// name of property MUST match that of ProfileSnapshot
		let version: ProfileSnapshot.Version
	}
}

extension ProfileSnapshot.Version {
	public static func fromJSON(
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

extension ProfileSnapshot {
	public static func validateCompatibility(
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

extension ProfileSnapshot {
	@discardableResult
	public static func validateVersionCompatibility(
		ofProfileSnapshotJSONData data: Data,
		jsonDecoder: JSONDecoder = .iso8601
	) throws -> Version {
		let decodedVersion = try Version.fromJSON(data: data, jsonDecoder: jsonDecoder)
		try validateCompatibility(version: decodedVersion)
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
	/// A version of the Profile Snapshot data format used for compatibility checks.
	public let version: Version

	/// A locally generated stable identfier of this Profile. Useful for checking if
	/// to Profiles which are inequal based on `Equatable` (content) might be the
	/// semantically the same, based on the ID.
	public let id: ID; public typealias ID = Profile.ID

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
		self.id = profile.id
		self.version = profile.version
		self.appPreferences = profile.appPreferences
		self.perNetwork = profile.perNetwork
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
		try ProfileSnapshot.validateCompatibility(version: snapshot.version)

		self.init(
			version: snapshot.version,
			id: snapshot.id,
			factorSources: snapshot.factorSources,
			appPreferences: snapshot.appPreferences,
			perNetwork: snapshot.perNetwork
		)
	}
}

extension ProfileSnapshot {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"version": version,
				"id": id,
				"factorSources": factorSources,
				"appPreferences": appPreferences,
				"perNetwork": perNetwork,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		factorSources: \(factorSources),
		appPreferences: \(appPreferences),
		perNetwork: \(perNetwork),
		"""
	}
}
