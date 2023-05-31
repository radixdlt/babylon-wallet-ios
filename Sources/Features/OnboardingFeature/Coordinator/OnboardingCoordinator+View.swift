import CreateAccountFeature
import FeaturePrelude

// MARK: - OnboardingCoordinator.View
extension OnboardingCoordinator {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<OnboardingCoordinator>

		public init(store: StoreOf<OnboardingCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			SwitchStore(store) {
				CaseLet(
					state: /OnboardingCoordinator.State.startup,
					action: { OnboardingCoordinator.Action.child(.startup($0)) },
					then: { OnboardingStartup.View(store: $0) }
				)
				CaseLet(
					state: /OnboardingCoordinator.State.createAccountCoordinator,
					action: { OnboardingCoordinator.Action.child(.createAccountCoordinator($0)) },
					then: {
						CreateAccountCoordinator.View(store: $0)
							.padding(.top, .medium3)
					}
				)
			}
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

extension OnboardingCoordinator.State {
	public static let previewValue: Self = {
		fatalError("impl me")
	}()
}
#endif
