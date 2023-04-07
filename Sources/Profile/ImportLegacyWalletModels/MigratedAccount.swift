import Prelude

// MARK: - MigratedAccount
public struct MigratedAccount: Sendable, Hashable {
	public let olympia: OlympiaAccountToMigrate
	public let babylon: Profile.Network.Account
	public init(olympia: OlympiaAccountToMigrate, babylon: Profile.Network.Account) {
		self.olympia = olympia
		self.babylon = babylon
	}
}
