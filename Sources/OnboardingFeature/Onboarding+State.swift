import ComposableArchitecture
import ImportProfileFeature
import Mnemonic

// MARK: Onboarding.State
public extension Onboarding {
	// MARK: State
	struct State: Equatable {
		public var newProfile: NewProfile.State?
		public var importProfile: ImportProfile.State?
		public var importMnemonic: ImportMnemonic.State?
		public init(
			newProfile: NewProfile.State? = nil,
			importProfile: ImportProfile.State? = nil,
			importMnemonic: ImportMnemonic.State? = nil
		) {
			self.newProfile = newProfile
			self.importProfile = importProfile
			self.importMnemonic = importMnemonic
		}
	}
}
