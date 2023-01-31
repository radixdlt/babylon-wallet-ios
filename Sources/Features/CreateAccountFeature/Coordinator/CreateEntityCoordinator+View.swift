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
		SwitchStore(store.scope(state: \.step)) {
			CaseLet(
				state: /CreateEntityCoordinator.State.Step.nameNewEntity,
				action: { CreateEntityCoordinator.Action.child(.nameNewEntity($0)) },
				then: { NameNewEntity.View(store: $0) }
			)
			CaseLet(
				state: /CreateEntityCoordinator.State.Step.selectGenesisFactorSource,
				action: { CreateEntityCoordinator.Action.child(.selectGenesisFactorSource($0)) },
				then: { SelectGenesisFactorSource.View(store: $0) }
			)
//			CaseLet(
//				state: /CreateEntityCoordinator.State.Root.completion,
//				action: { CreateEntityCoordinator.Action.child(.completion($0)) },
			//                then: { NewEntityCompletion<CompletionState.Entity>.View(store: $0) }
//			)
		}
	}
}
