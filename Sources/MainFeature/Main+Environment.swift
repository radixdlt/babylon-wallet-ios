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
	// MARK: Environment
	struct Environment {
		public let backgroundQueue: AnySchedulerOf<DispatchQueue>
		public let mainQueue: AnySchedulerOf<DispatchQueue>
		public let userDefaultsClient: UserDefaultsClient
		public init(
			backgroundQueue: AnySchedulerOf<DispatchQueue>,
			mainQueue: AnySchedulerOf<DispatchQueue>,
			userDefaultsClient: UserDefaultsClient
		) {
			self.backgroundQueue = backgroundQueue
			self.mainQueue = mainQueue
			self.userDefaultsClient = userDefaultsClient
		}
	}
}
