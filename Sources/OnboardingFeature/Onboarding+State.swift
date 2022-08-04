import Common
import ComposableArchitecture
import Foundation
import Profile
import UserDefaultsClient
import Wallet

// MARK: - Onboarding
/// Namespace for OnboardingFeature
public enum Onboarding {}

public extension Onboarding {
	// MARK: State
	struct State: Equatable {
		// Just for initial testing
		@BindableState public var profileName: String
		public var canProceed: Bool

		public init(
			profileName: String = "",
			canProceed: Bool = false
		) {
			self.profileName = profileName
			self.canProceed = canProceed
		}
	}
}
