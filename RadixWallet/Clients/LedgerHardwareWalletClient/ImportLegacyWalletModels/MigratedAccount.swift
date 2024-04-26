

// MARK: - MigratedAccount
public struct MigratedAccount: Sendable, Hashable {
	public let olympia: OlympiaAccountToMigrate
	public let babylon: Account
	public init(olympia: OlympiaAccountToMigrate, babylon: Account) {
		self.olympia = olympia
		self.babylon = babylon
	}
}
