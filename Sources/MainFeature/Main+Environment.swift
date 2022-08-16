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
		public let wallet: Wallet

		public init(
			backgroundQueue: AnySchedulerOf<DispatchQueue>,
			mainQueue: AnySchedulerOf<DispatchQueue>,
			userDefaultsClient: UserDefaultsClient,
			wallet: Wallet
		) {
			self.backgroundQueue = backgroundQueue
			self.mainQueue = mainQueue
			self.userDefaultsClient = userDefaultsClient
			self.wallet = wallet
		}
	}
}
