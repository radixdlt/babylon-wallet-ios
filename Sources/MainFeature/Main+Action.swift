//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-07-01.
//

import Common
import ComposableArchitecture
import Foundation
import UserDefaultsClient
import Wallet

public extension Main {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalActions)
		case coordinate(CoordinatingAction)
	}
}

public extension Main.Action {
	enum InternalActions: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension Main.Action.InternalActions {
	enum UserAction: Equatable {
		case removeWallet
	}
}

public extension Main.Action.InternalActions {
	enum SystemAction: Equatable {
		case removedWallet
	}
}

public extension Main.Action {
	enum CoordinatingAction: Equatable {
		case removedWallet
	}
}
