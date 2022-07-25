//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-07-01.
//

import Common
import ComposableArchitecture
import Foundation
import HomeFeature
import UserDefaultsClient
import Wallet

// MARK: - Main
/// Namespace for MainFeature
public enum Main {}

public extension Main {
	// MARK: State
	struct State: Equatable {
		public var wallet: Wallet
		public var home: Home.State?

		public init(
			wallet: Wallet,
			home: Home.State? = .init()
		) {
			self.wallet = wallet
			self.home = home
		}
	}
}
