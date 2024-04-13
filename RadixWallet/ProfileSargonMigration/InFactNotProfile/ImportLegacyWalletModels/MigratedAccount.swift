

// MARK: - MigratedAccount
public struct MigratedAccount: Sendable, Hashable {
	public let olympia: OlympiaAccountToMigrate
	public let babylon: Sargon.Account
	public init(olympia: OlympiaAccountToMigrate, babylon: Sargon.Account) {
		self.olympia = olympia
		self.babylon = babylon
	}
}
