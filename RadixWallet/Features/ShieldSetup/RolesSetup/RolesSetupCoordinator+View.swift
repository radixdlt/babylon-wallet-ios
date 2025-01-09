// MARK: - RolesSetupCoordinator.View
extension RolesSetupCoordinator {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<RolesSetupCoordinator>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				Group {
					switch store.path.case {
					case let .regularAccessSetup(store):
						RegularAccessSetup.View(store: store)
					}
				}
			}
		}
	}
}

private extension StoreOf<RolesSetupCoordinator> {
	var path: StoreOf<RolesSetupCoordinator.Path> {
		scope(state: \.path, action: \.child.path)
	}
}
