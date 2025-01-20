import ComposableArchitecture
import SwiftUI

// MARK: - ChooseAccountsRow
enum ChooseAccountsRow {
	struct State: Sendable, Hashable {
		enum Mode: Sendable, Hashable {
			case checkmark
			case radioButton
		}

		let account: Account
		let mode: Mode
		let isEnabled: Bool

		init(
			account: Account,
			mode: Mode,
			isEnabled: Bool = true
		) {
			self.account = account
			self.mode = mode
			self.isEnabled = isEnabled
		}
	}
}
