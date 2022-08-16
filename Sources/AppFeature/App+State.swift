import ComposableArchitecture
import HomeFeature
import MainFeature
import OnboardingFeature
import ProfileLoader
import SplashFeature
import UserDefaultsClient
import Wallet
import WalletLoader

// MARK: - App
/// Namespace for AppFeature
public enum App {}

public extension App {
	enum State: Equatable {
		case alert(AlertState<Action>?)
		case main(Main.State?)
		case onboarding(Onboarding.State?)
		case splash(Splash.State?)

		public init() { self = .onboarding(.init()) }
		// FIXME: wallet
//		public init() { self = .main(.placeholder) }
	}
}
