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

// MARK: - Main
/// Namespace for MainFeature
public enum Main {}

public extension Main {
	// MARK: State
	struct State: Equatable {
		public var wallet: Wallet
		public init(wallet: Wallet) {
			self.wallet = wallet
		}
	}
}
