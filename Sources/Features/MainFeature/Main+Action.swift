import HandleDappRequests
import HomeFeature
import SettingsFeature

// MARK: - Main.Action
public extension Main {
	// MARK: Action
	enum Action: Sendable, Equatable {
		case child(ChildAction)
		case delegate(Delegate)
	}
}

// MARK: - Main.Action.ChildAction
public extension Main.Action {
	enum ChildAction: Sendable, Equatable {
		case home(Home.Action)
		case settings(Settings.Action)
		case handleDappRequest(HandleDappRequests.Action)
	}
}

// MARK: - Main.Action.Delegate
public extension Main.Action {
	enum Delegate: Sendable, Equatable {
		case removedWallet
	}
}
