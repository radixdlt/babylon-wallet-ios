import Prelude

// MARK: - AppPreferences.Security
extension AppPreferences {
	public struct Security:
		Sendable,
		Hashable,
		Codable,
		CustomStringConvertible,
		CustomDumpReflectable
	{
		public var structureConfigurations: OrderedSet<SecurityStructureConfiguration>
		public var isCloudProfileSyncEnabled: Bool
		public var isDeveloperModeEnabled: Bool

		public init(
			structureConfigurations: OrderedSet<SecurityStructureConfiguration> = [],
			isCloudProfileSyncEnabled: Bool = true,
			isDeveloperModeEnabled: Bool = true
		) {
			self.structureConfigurations = structureConfigurations
			self.isCloudProfileSyncEnabled = isCloudProfileSyncEnabled
			self.isDeveloperModeEnabled = isDeveloperModeEnabled
		}
	}
}

extension AppPreferences.Security {
	public static let `default` = Self()
}

extension AppPreferences.Security {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"structureConfigurations": structureConfigurations,
				"isCloudProfileSyncEnabled": isCloudProfileSyncEnabled,
				"isDeveloperModeEnabled": isDeveloperModeEnabled,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		structureConfigurations: \(structureConfigurations),
		isCloudProfileSyncEnabled: \(isCloudProfileSyncEnabled),
		isDeveloperModeEnabled: \(isDeveloperModeEnabled)
		"""
	}
}
