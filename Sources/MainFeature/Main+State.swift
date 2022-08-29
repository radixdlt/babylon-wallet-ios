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
		public var home: Home.State
		public var settings: Settings.State?
		public var isCurrencyAmountVisible: Bool

		public init(
			home: Home.State = .placeholder, // TODO: remove placeholder
			settings: Settings.State? = nil,
			isCurrencyAmountVisible: Bool = false
		) {
			self.home = home
			self.settings = settings
			self.isCurrencyAmountVisible = isCurrencyAmountVisible
		}
	}
}

#if DEBUG
public extension Main.State {
	static let placeholder = Self(
		home: .init(),
		settings: nil,
		isCurrencyAmountVisible: false
	)
}
#endif
