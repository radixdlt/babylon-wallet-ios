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
		public var iCloudProfileSyncEnabled: IsIcloudProfileSyncEnabled
		public var isDeveloperModeEnabled: IsDeveloperModeEnabled

		public init(
			iCloudProfileSyncEnabled: IsIcloudProfileSyncEnabled = .default,
			isDeveloperModeEnabled: IsDeveloperModeEnabled = .default
		) {
			self.iCloudProfileSyncEnabled = iCloudProfileSyncEnabled
			self.isDeveloperModeEnabled = isDeveloperModeEnabled
		}
	}
}

extension AppPreferences.Security {
	public enum IsIcloudProfileSyncEnabledTag {}
	public typealias IsIcloudProfileSyncEnabled = Tagged<IsIcloudProfileSyncEnabledTag, Bool>
	public enum IsDeveloperModeEnabledTag {}
	public typealias IsDeveloperModeEnabled = Tagged<IsDeveloperModeEnabledTag, Bool>
}

extension AppPreferences.Security.IsDeveloperModeEnabled {
	// FIXME: Mainnet: change to `false`
	public static let `default`: Self = true
}

extension AppPreferences.Security.IsIcloudProfileSyncEnabled {
	public static let `default`: Self = true
}

extension AppPreferences.Security {
	public static let `default` = Self()
}

extension AppPreferences.Security {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"iCloudProfileSyncEnabled": iCloudProfileSyncEnabled.rawValue,
				"isDeveloperModeEnabled": isDeveloperModeEnabled.rawValue,
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
