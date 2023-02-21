import HomeFeature
import SettingsFeature

// MARK: - Main.Action
extension Main {
	// MARK: Action
	public enum Action: Sendable, Equatable {
		case child(ChildAction)
		case delegate(Delegate)
	}
}

// MARK: - Main.Action.ChildAction
extension Main.Action {
	public enum ChildAction: Sendable, Equatable {
		case home(Home.Action)
		case settings(AppSettings.Action)
	}
}

// MARK: - Main.Action.Delegate
extension Main.Action {
	public enum Delegate: Sendable, Equatable {
		case removedWallet
	}
}
