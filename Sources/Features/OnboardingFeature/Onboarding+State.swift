import ComposableArchitecture
import CreateAccountFeature
import ImportProfileFeature

// MARK: - Onboarding.State
public extension Onboarding {
	// MARK: State
	struct State: Equatable {
		public enum Root: Equatable {
			case importProfile(ImportProfile.State)
			case createAccount(CreateAccount.State)
		}

		public var root: Root

		public init(root: Root = .createAccount(.init(shouldCreateProfile: true))) {
			self.root = root
		}
	}
}

#if DEBUG
public extension Onboarding.State {
	static let previewValue: Self = .init()
}
#endif
