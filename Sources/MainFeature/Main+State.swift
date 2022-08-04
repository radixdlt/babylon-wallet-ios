import Common
import ComposableArchitecture
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
		public var wallet: Wallet
		public var home: Home.State
		public var settings: Settings.State?

		public init(
			wallet: Wallet,
			home: Home.State = .init(),
			settings: Settings.State? = nil
		) {
			self.wallet = wallet
			self.home = home
			self.settings = settings
		}
	}
}
