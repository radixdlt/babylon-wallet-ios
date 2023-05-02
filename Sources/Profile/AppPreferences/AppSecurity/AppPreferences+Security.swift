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
		public var isCloudProfileSyncEnabled: IsCloudProfileSyncEnabled
		public var isDeveloperModeEnabled: IsDeveloperModeEnabled

		public init(
			isCloudProfileSyncEnabled: IsCloudProfileSyncEnabled = .default,
			isDeveloperModeEnabled: IsDeveloperModeEnabled = .default
		) {
			self.isCloudProfileSyncEnabled = isCloudProfileSyncEnabled
			self.isDeveloperModeEnabled = isDeveloperModeEnabled
		}
	}
}

extension AppPreferences.Security {
	public enum IsCloudProfileSyncEnabledTag {}
	public typealias IsCloudProfileSyncEnabled = Tagged<IsCloudProfileSyncEnabledTag, Bool>
	public enum IsDeveloperModeEnabledTag {}
	public typealias IsDeveloperModeEnabled = Tagged<IsDeveloperModeEnabledTag, Bool>
}

extension AppPreferences.Security.IsDeveloperModeEnabled {
	// FIXME: Mainnet: change to `false`
	public static let `default`: Self = true
}

extension AppPreferences.Security.IsCloudProfileSyncEnabled {
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
				"isCloudProfileSyncEnabled": isCloudProfileSyncEnabled.rawValue,
				"isDeveloperModeEnabled": isDeveloperModeEnabled.rawValue,
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
