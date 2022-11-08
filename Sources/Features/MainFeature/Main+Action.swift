import HomeFeature
import SettingsFeature

// MARK: - Main.Action
public extension Main {
	// MARK: Action
	enum Action: Equatable {
		case child(ChildAction)
		case coordinate(CoordinateAction)
	}
}

public extension Main.Action {
	enum ChildAction: Equatable {
		case home(Home.Action)
		case settings(Settings.Action)
	}
}

// MARK: - Main.Action.CoordinateAction
public extension Main.Action {
	enum CoordinateAction: Equatable {
		case removedWallet
	}
}
