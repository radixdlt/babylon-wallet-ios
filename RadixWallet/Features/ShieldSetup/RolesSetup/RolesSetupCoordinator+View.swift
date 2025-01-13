// MARK: - RolesSetupCoordinator.View
extension RolesSetupCoordinator {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<RolesSetupCoordinator>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				Group {
					switch store.path.case {
					case let .primaryRoleSetup(store):
						PrimaryRoleSetup.View(store: store)
					}
				}
				.destinations(with: store)
			}
		}
	}
}

private extension StoreOf<RolesSetupCoordinator> {
	var path: StoreOf<RolesSetupCoordinator.Path> {
		scope(state: \.path, action: \.child.path)
	}

	var destination: PresentationStoreOf<RolesSetupCoordinator.Destination> {
		func scopeState(state: State) -> PresentationState<RolesSetupCoordinator.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<RolesSetupCoordinator>) -> some View {
		let destinationStore = store.destination
		return chooseFactorSource(with: destinationStore)
	}

	private func chooseFactorSource(with destinationStore: PresentationStoreOf<RolesSetupCoordinator.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.chooseFactorSource, action: \.chooseFactorSource)) {
			ChooseFactorSourceCoordinator.View(store: $0)
		}
	}
}
