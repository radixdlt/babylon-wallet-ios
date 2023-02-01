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
		WithViewStore(store, observe: { $0 }) { _ in
			//            VStack {
			//                NavigationBar(
			//                    leadingItem: Group { viewStore.canBeDismissed ? CloseButton {
			//                        viewStore.send(.closeButtonTapped)
			//                    } : EmptyView() }
			//                )
			//                .foregroundColor(.app.gray1)
			//                .padding([.horizontal, .top], .medium3)
//
//
			//            }
			SwitchStore(store.scope(state: \.step)) {
				CaseLet(
					state: /CreateEntityCoordinator.State.Step.step0_nameNewEntity,
					action: { CreateEntityCoordinator.Action.child(.step0_nameNewEntity($0)) },
					then: { NameNewEntity.View(store: $0) }
				)
//				CaseLet(
//					state: /CreateEntityCoordinator.State.Step.selectGenesisFactorSource,
//					action: { CreateEntityCoordinator.Action.child(.selectGenesisFactorSource($0)) },
//					then: { SelectGenesisFactorSource.View(store: $0) }
//				)
//				//            CaseLet(
//				//                state: /CreateEntityCoordinator.State.Root.completion,
//				//                action: { CreateEntityCoordinator.Action.child(.completion($0)) },
//				//                then: { NewEntityCompletion<CompletionState.Entity>.View(store: $0) }
//				//            )
			}
		}
	}
}
