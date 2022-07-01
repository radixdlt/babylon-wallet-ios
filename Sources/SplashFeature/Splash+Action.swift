//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-07-01.
//

import Common
import ComposableArchitecture
import Foundation
import Profile
import ProfileLoader
import Wallet
import WalletLoader

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
	case noWallet(reason: NoWalletLoaded)

	public enum NoWalletLoaded: Equatable {
		case noProfileFoundAtPath(String)
		case failedToLoadProfileFromDocument
		case secretsNotFoundForProfile(Profile)
	}
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
		case loadProfileResult(Result<Profile, ProfileLoader.Error>)
		case loadWalletWithProfile(Profile)
		case loadWalletWithProfileResult(Result<Wallet, WalletLoader.Error>, profile: Profile)

		case viewDidAppear
	}
}
