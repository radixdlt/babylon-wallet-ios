import CreateEntityFeature
import FeaturePrelude

// MARK: - OnboardingCoordinator.View
extension OnboardingCoordinator {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<OnboardingCoordinator>

		public init(store: StoreOf<OnboardingCoordinator>) {
			self.store = store
		}
	}
}

extension OnboardingCoordinator.View {
	public var body: some View {
		SwitchStore(store) {
			CaseLet(
				state: /OnboardingCoordinator.State.importProfile,
				action: { OnboardingCoordinator.Action.child(.importProfile($0)) },
				then: { ImportProfile.View(store: $0) }
			)
			CaseLet(
				state: /OnboardingCoordinator.State.createAccountCoordinator,
				action: { OnboardingCoordinator.Action.child(.createAccountCoordinator($0)) },
				then: { CreateAccountCoordinator.View(store: $0) }
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
