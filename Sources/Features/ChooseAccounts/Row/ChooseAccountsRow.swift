import FeaturePrelude

// MARK: - ChooseAccountsRow
public enum ChooseAccountsRow {
	public struct State: Sendable, Hashable {
		public enum Mode {
			case checkmark
			case radioButton
		}

		public let account: Profile.Network.Account
		public let mode: Mode

		public init(
			account: Profile.Network.Account,
			mode: Mode
		) {
			self.account = account
			self.mode = mode
		}
	}
}
