import FeaturePrelude

// MARK: - CreateEntityCoordinator.View
public extension CreateEntityCoordinator {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<CreateEntityCoordinator>

		public init(store: StoreOf<CreateEntityCoordinator>) {
			self.store = store
		}
	}
}

public extension CreateEntityCoordinator.View {
	var body: some View {
		WithViewStore(store, observe: { $0 }) { viewStore in
			ForceFullScreen {
				VStack {
					if viewStore.state.config.canBeDismissed {
						NavigationBar(
							leadingItem: CloseButton {
								viewStore.send(.view(.dismiss))
							}
						)
						.foregroundColor(.app.gray1)
						.padding([.horizontal, .top], .medium3)
					}
					SwitchStore(store.scope(state: \.step)) {
						CaseLet(
							state: /CreateEntityCoordinator.State.Step.step0_nameNewEntity,
							action: { CreateEntityCoordinator.Action.child(.step0_nameNewEntity($0)) },
							then: { NameNewEntity.View(store: $0) }
						)
						CaseLet(
							state: /CreateEntityCoordinator.State.Step.step1_selectGenesisFactorSource,
							action: { CreateEntityCoordinator.Action.child(.step1_selectGenesisFactorSource($0)) },
							then: { SelectGenesisFactorSource.View(store: $0) }
						)
						CaseLet(
							state: /CreateEntityCoordinator.State.Step.step2_creationOfEntity,
							action: { CreateEntityCoordinator.Action.child(.step2_creationOfEntity($0)) },
							then: { CreationOfEntity.View(store: $0) }
						)
						CaseLet(
							state: /CreateEntityCoordinator.State.Step.step3_completion,
							action: { CreateEntityCoordinator.Action.child(.step3_completion($0)) },
							then: { NewEntityCompletion.View(store: $0) }
						)
					}
				}
			}
		}
	}
}
