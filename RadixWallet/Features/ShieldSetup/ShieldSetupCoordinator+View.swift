import SwiftUI

// MARK: - ShieldSetupCoordinator.View
extension ShieldSetupCoordinator {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<ShieldSetupCoordinator>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				NavigationStack(path: $store.scope(state: \.path, action: \.child.path)) {
					ShieldSetupOnboarding.View(store: store.onboarding)
				} destination: { destination in
					switch destination.case {
					case let .prepareFactors(store):
						PrepareFactorSources.Coordinator.View(store: store)
					case let .selectFactors(store):
						SelectFactorSourcesCoordinator.View(store: store)
					case let .regularAccessSetup(store):
						RegularAccessSetup.View(store: store)
					}
				}
			}
		}
	}
}

private extension StoreOf<ShieldSetupCoordinator> {
	var onboarding: StoreOf<ShieldSetupOnboarding> {
		scope(state: \.onboarding, action: \.child.onboarding)
	}
}
