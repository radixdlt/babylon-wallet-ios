

// MARK: - MigratedAccount
struct MigratedAccount: Sendable, Hashable {
	let olympia: OlympiaAccountToMigrate
	let babylon: Account
	init(olympia: OlympiaAccountToMigrate, babylon: Account) {
		self.olympia = olympia
		self.babylon = babylon
	}
}
