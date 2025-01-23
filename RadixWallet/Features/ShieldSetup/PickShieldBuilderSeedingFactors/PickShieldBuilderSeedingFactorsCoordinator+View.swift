import SwiftUI

// MARK: - PickShieldBuilderSeedingFactorsCoordinator.View
extension PickShieldBuilderSeedingFactorsCoordinator {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<PickShieldBuilderSeedingFactorsCoordinator>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				Group {
					switch store.path.case {
					case let .pickShieldBuilderSeedingFactors(store):
						PickShieldBuilderSeedingFactors.View(store: store)
					}
				}
			}
		}
	}
}

private extension StoreOf<PickShieldBuilderSeedingFactorsCoordinator> {
	var path: StoreOf<PickShieldBuilderSeedingFactorsCoordinator.Path> {
		scope(state: \.path, action: \.child.path)
	}
}
