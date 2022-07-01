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
	// MARK: Environment
	struct Environment {
		public let backgroundQueue: AnySchedulerOf<DispatchQueue>
		public let mainQueue: AnySchedulerOf<DispatchQueue>
		public let profileLoader: ProfileLoader
		public let walletLoader: WalletLoader
		public init(
			backgroundQueue: AnySchedulerOf<DispatchQueue>,
			mainQueue: AnySchedulerOf<DispatchQueue>,
			profileLoader: ProfileLoader,
			walletLoader: WalletLoader
		) {
			self.backgroundQueue = backgroundQueue
			self.mainQueue = mainQueue
			self.profileLoader = profileLoader
			self.walletLoader = walletLoader
		}
	}
}
