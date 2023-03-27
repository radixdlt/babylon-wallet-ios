import FeaturePrelude

// MARK: - ChooseAccountsRow
enum ChooseAccountsRow {
	struct State: Sendable, Hashable {
		enum Mode {
			case checkmark
			case radioButton
		}

		let account: Profile.Network.Account
		let mode: Mode

		init(
			account: Profile.Network.Account,
			mode: Mode
		) {
			self.account = account
			self.mode = mode
		}
	}
}
