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
					case let .addShieldBuilderSeedingFactors(store):
						AddShieldBuilderSeedingFactors.Coordinator.View(store: store)
					case let .pickShieldBuilderSeedingFactors(store):
						PickShieldBuilderSeedingFactorsCoordinator.View(store: store)
					case let .rolesSetup(store):
						RolesSetupCoordinator.View(store: store)
					case let .nameShield(store):
						NameShield.View(store: store)
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
