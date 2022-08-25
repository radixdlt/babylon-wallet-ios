import Common
import ComposableArchitecture
import CreateAccount
import Foundation
import HomeFeature
import SettingsFeature
import UserDefaultsClient
import Wallet

// MARK: - Main
/// Namespace for MainFeature
public enum Main {}

public extension Main {
	// MARK: State
	struct State: Equatable {
		public var account: Home.AccountDetails.State?
		public var accountPreferences: Home.AccountPreferences.State?
		public var home: Home.State
		public var settings: Settings.State?
		public var createAccount: CreateAccount.State?

		public init(
			account: Home.AccountDetails.State? = nil,
			accountPreferences: Home.AccountPreferences.State? = nil,
			home: Home.State = .placeholder, // TODO: remove placeholder
			settings: Settings.State? = nil,
			createAccount: CreateAccount.State? = nil
		) {
			self.account = account
			self.accountPreferences = accountPreferences
			self.home = home
			self.settings = settings
			self.createAccount = createAccount
		}
	}
}

#if DEBUG
public extension Main.State {
	static let placeholder = Self(
		home: .init(),
		settings: nil
	)
}
#endif
