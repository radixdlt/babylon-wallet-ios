import BrowerExtensionsConnectivityFeature
import HomeFeature
import SettingsFeature

// MARK: - Main.Action
public extension Main {
	// MARK: Action
	enum Action: Equatable {
		case coordinate(CoordinateAction)

		case home(Home.Action)
		case settings(Settings.Action)
		case browerExtensionsConnectivity(BrowerExtensionsConnectivity.Action)
	}
}

// MARK: - Main.Action.CoordinateAction
public extension Main.Action {
	enum CoordinateAction: Equatable {
		case removedWallet
	}
}
