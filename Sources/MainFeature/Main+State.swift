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

		public init(
			home: Home.State = .init(),
			settings: Settings.State? = nil
		) {
			self.home = home
			self.settings = settings
		}
	}
}

#if DEBUG
public extension Main.State {
	static let placeholder = Main.State(
		home: .init(),
		settings: nil
	)
}
#endif
