import CreateEntityFeature
import FeaturePrelude

// MARK: - OnboardingCoordinator.View
public extension OnboardingCoordinator {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<OnboardingCoordinator>

		public init(store: StoreOf<OnboardingCoordinator>) {
			self.store = store
		}
	}
}

public extension OnboardingCoordinator.View {
	var body: some View {
		SwitchStore(store) {
			CaseLet(
				state: /OnboardingCoordinator.State.importProfile,
				action: { OnboardingCoordinator.Action.child(.importProfile($0)) },
				then: { ImportProfile.View(store: $0) }
			)
			CaseLet(
				state: /OnboardingCoordinator.State.newProfileThenAccountCoordinator,
				action: { OnboardingCoordinator.Action.child(.newProfileThenAccountCoordinator($0)) },
				then: { NewProfileThenAccountCoordinator.View(store: $0) }
			)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct Onboarding_Preview: PreviewProvider {
	static var previews: some View {
		OnboardingCoordinator.View(
			store: .init(
				initialState: .previewValue,
				reducer: OnboardingCoordinator()
			)
		)
	}
}
#endif
