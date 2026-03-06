

// MARK: - MigratedAccount
struct MigratedAccount: Hashable {
	let olympia: OlympiaAccountToMigrate
	let babylon: Account
}
