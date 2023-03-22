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
		public var iCloudProfileSyncEnabled: Bool
		public var isDeveloperModeEnabled: Bool

		public init(
			iCloudProfileSyncEnabled: Bool = true,
			isDeveloperModeEnabled: Bool = true
		) {
			self.iCloudProfileSyncEnabled = iCloudProfileSyncEnabled
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
				"iCloudProfileSyncEnabled": iCloudProfileSyncEnabled,
				"isDeveloperModeEnabled": isDeveloperModeEnabled,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		iCloudProfileSyncEnabled: \(iCloudProfileSyncEnabled),
		  isDeveloperModeEnabled: \(isDeveloperModeEnabled)
		"""
	}
}
