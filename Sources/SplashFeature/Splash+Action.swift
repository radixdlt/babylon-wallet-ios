import ComposableArchitecture
import Profile
import Wallet

public extension Splash {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

// MARK: - SplashLoadWalletResult
public enum SplashLoadWalletResult: Equatable {
	case walletLoaded(Wallet)
	case noWallet(reason: String, failedToDecode: Bool)
}

public extension Splash.Action {
	enum CoordinatingAction: Equatable {
		case loadWalletResult(SplashLoadWalletResult)
	}
}

public extension Splash.Action {
	enum InternalAction: Equatable {
		/// So we can use a single exit path, and `delay` to display this Splash for at
		/// least 500 ms or suitable time
		case coordinate(CoordinatingAction)

		case system(SystemAction)
	}
}

public extension Splash.Action.InternalAction {
	enum SystemAction: Equatable {
		case loadProfile
		case loadProfileResult(TaskResult<Profile>)
		case loadWalletWithProfile(Profile)
		case loadWalletWithProfileResult(TaskResult<Wallet>, profile: Profile)

		case viewDidAppear
	}
}
