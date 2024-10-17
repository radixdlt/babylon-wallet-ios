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

		init(
			account: Account,
			mode: Mode
		) {
			self.account = account
			self.mode = mode
		}
	}
}
