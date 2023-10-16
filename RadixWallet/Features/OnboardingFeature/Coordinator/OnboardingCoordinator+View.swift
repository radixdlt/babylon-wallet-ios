import ComposableArchitecture
import SwiftUI

// MARK: - OnboardingCoordinator.View
extension OnboardingCoordinator {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<OnboardingCoordinator>

		public init(store: StoreOf<OnboardingCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			SwitchStore(store.scope(state: \.root, action: Action.child)) { state in
				switch state {
				case .startup:
					CaseLet(
						/OnboardingCoordinator.State.Root.startup,
						action: OnboardingCoordinator.ChildAction.startup,
						then: { OnboardingStartup.View(store: $0) }
					)
				case .createAccountCoordinator:
					CaseLet(
						/OnboardingCoordinator.State.Root.createAccountCoordinator,
						action: OnboardingCoordinator.ChildAction.createAccountCoordinator,
						then: {
							CreateAccountCoordinator.View(store: $0)
								.padding(.top, .medium3)
						}
					)
				}
			}
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI
struct Onboarding_Preview: PreviewProvider {
	static var previews: some View {
		OnboardingCoordinator.View(
			store: .init(
				initialState: .previewValue,
				reducer: OnboardingCoordinator.init
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
