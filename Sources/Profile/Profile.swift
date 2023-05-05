import Prelude

// MARK: - Profile
public struct Profile:
	Sendable,
	Hashable,
	CustomStringConvertible,
	CustomDumpReflectable,
	Identifiable
{
	public var id: ProfileSnapshot.Header.ID {
		header.id
	}

	public var version: ProfileSnapshot.Header.Version {
		header.snapshotVersion
	}

	public let header: ProfileSnapshot.Header

	/// All sources of factors, used for authorization such as spending funds, contains no
	/// secrets.
	public var factorSources: FactorSources

	/// Settings for this profile in the app, contains default security configs
	/// as well as display settings.
	public var appPreferences: AppPreferences

	/// Effectivly **per network**: a list of accounts, personas and connected dApps.
	public var networks: Networks

	public init(
		header: ProfileSnapshot.Header,
		factorSources: FactorSources,
		appPreferences: AppPreferences,
		networks: Networks
	) {
		self.header = header
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

		let date = Date()
		self.init(
			header: .init(creatingDevice: creatingDevice, id: uuid(), creationDate: date, lastModified: date),
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
