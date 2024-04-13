import ComposableArchitecture
import SwiftUI

// MARK: - ChooseAccountsRow
public enum ChooseAccountsRow {
	public struct State: Sendable, Hashable {
		public enum Mode: Sendable, Hashable {
			case checkmark
			case radioButton
		}

		public let account: Sargon.Account
		public let mode: Mode

		public init(
			account: Sargon.Account,
			mode: Mode
		) {
			self.account = account
			self.mode = mode
		}
	}
}
