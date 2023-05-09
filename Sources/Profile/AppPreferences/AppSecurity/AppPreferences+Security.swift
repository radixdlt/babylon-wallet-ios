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
		public var isCloudProfileSyncEnabled: Bool
		public var isDeveloperModeEnabled: Bool

		public init(
			isCloudProfileSyncEnabled: Bool = true,
			isDeveloperModeEnabled: Bool = true
		) {
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
				"isCloudProfileSyncEnabled": isCloudProfileSyncEnabled,
				"isDeveloperModeEnabled": isDeveloperModeEnabled,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		isCloudProfileSyncEnabled: \(isCloudProfileSyncEnabled),
		  isDeveloperModeEnabled: \(isDeveloperModeEnabled)
		"""
	}
}
