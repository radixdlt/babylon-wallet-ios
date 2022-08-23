import Common
import ComposableArchitecture
import MainFeature
import OnboardingFeature
import PasteboardClient
import ProfileLoader
import SplashFeature
import UserDefaultsClient
import Wallet
import WalletLoader

public extension App {
	// MARK: Environment
	struct Environment {
		public let backgroundQueue: AnySchedulerOf<DispatchQueue>
		public let mainQueue: AnySchedulerOf<DispatchQueue>
		public let pasteboardClient: PasteboardClient
		public let profileLoader: ProfileLoader
		public let userDefaultsClient: UserDefaultsClient
		public let walletLoader: WalletLoader

		public init(
			backgroundQueue: AnySchedulerOf<DispatchQueue>,
			mainQueue: AnySchedulerOf<DispatchQueue>,
			pasteboardClient: PasteboardClient,
			profileLoader: ProfileLoader,
			userDefaultsClient: UserDefaultsClient,
			walletLoader: WalletLoader
		) {
			self.backgroundQueue = backgroundQueue
			self.mainQueue = mainQueue
			self.pasteboardClient = pasteboardClient
			self.profileLoader = profileLoader
			self.userDefaultsClient = userDefaultsClient
			self.walletLoader = walletLoader
		}
	}
}

#if DEBUG
public extension App.Environment {
	static let noop = Self(
		backgroundQueue: .immediate,
		mainQueue: .immediate,
		pasteboardClient: .noop,
		profileLoader: .noop,
		userDefaultsClient: .noop,
		walletLoader: .noop
	)
}
#endif
