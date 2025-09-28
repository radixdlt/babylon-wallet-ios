import SwiftUI

// MARK: - EditSecurityShieldCoordinator.View
extension EditSecurityShieldCoordinator {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<EditSecurityShieldCoordinator>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				NavigationStack(path: $store.scope(state: \.path, action: \.child.path)) {
					RolesSetupCoordinator.View(store: store.rolesSetup)
						.toolbar {
							ToolbarItem(placement: .topBarLeading) {
								CloseButton {
									store.send(.view(.closeButtonTapped))
								}
							}
						}
				} destination: { destination in
					switch destination.case {
					case let .rolesSetup(store):
						RolesSetupCoordinator.View(store: store)
					}
				}
			}
		}
	}
}

private extension StoreOf<EditSecurityShieldCoordinator> {
	var rolesSetup: StoreOf<RolesSetupCoordinator> {
		scope(state: \.rolesSetup, action: \.child.rolesSetup)
	}
}
