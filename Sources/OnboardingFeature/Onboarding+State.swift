import ComposableArchitecture
import ImportProfileFeature
import Mnemonic

// MARK: Onboarding.State
public extension Onboarding {
	// MARK: State
	struct State: Equatable {
		public var newProfile: NewProfile.State?
		public var importProfile: ImportProfile.State?
		public init() {}
	}
}
