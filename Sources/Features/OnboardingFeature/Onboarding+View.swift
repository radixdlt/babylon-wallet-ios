import CreateEntityFeature
import CreateProfileFeature
import FeaturePrelude

// MARK: - Onboarding.View
public extension Onboarding {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<Onboarding>

		public init(store: StoreOf<Onboarding>) {
			self.store = store
		}
	}
}

public extension Onboarding.View {
	var body: some View {
		SwitchStore(store) {
			CaseLet(
				state: /Onboarding.State.createProfile,
				action: { Onboarding.Action.child(.createProfile($0)) },
				then: { CreateProfileCoordinator.View(store: $0) }
			)
			CaseLet(
				state: /Onboarding.State.createAccountCoordinator,
				action: { Onboarding.Action.child(.createAccountCoordinator($0)) },
				then: { CreateAccountCoordinator.View(store: $0) }
			)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct Onboarding_Preview: PreviewProvider {
	static var previews: some View {
		Onboarding.View(
			store: .init(
				initialState: .previewValue,
				reducer: Onboarding()
			)
		)
	}
}
#endif
