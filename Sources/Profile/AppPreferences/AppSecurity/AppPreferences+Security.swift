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
		public var structureConfigurationReferences: IdentifiedArrayOf<SecurityStructureConfigurationReference>
		public var isCloudProfileSyncEnabled: Bool
		public var isDeveloperModeEnabled: Bool

		public init(
			structureConfigurationReferences: IdentifiedArrayOf<SecurityStructureConfigurationReference> = [],
			isCloudProfileSyncEnabled: Bool = true,
			isDeveloperModeEnabled: Bool = false
		) {
			self.structureConfigurationReferences = structureConfigurationReferences
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
				"structureConfigurationReferences": structureConfigurationReferences,
				"isCloudProfileSyncEnabled": isCloudProfileSyncEnabled,
				"isDeveloperModeEnabled": isDeveloperModeEnabled,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		structureConfigurationReferences: \(structureConfigurationReferences),
		isCloudProfileSyncEnabled: \(isCloudProfileSyncEnabled),
		isDeveloperModeEnabled: \(isDeveloperModeEnabled)
		"""
	}
}
