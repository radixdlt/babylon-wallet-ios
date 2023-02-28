import FeaturePrelude

extension CreateEntityCoordinator.State {
	fileprivate var viewState: CreateEntityCoordinator.ViewState {
		.init(shouldDisplayNavBar: shouldDisplayNavBar)
	}
}

// MARK: - CreateEntityCoordinator.View
extension CreateEntityCoordinator {
	public struct ViewState: Sendable, Equatable {
		let shouldDisplayNavBar: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CreateEntityCoordinator>

		public init(store: StoreOf<CreateEntityCoordinator>) {
			self.store = store
		}
	}
}

extension CreateEntityCoordinator.View {
	public var body: some View {
		WithViewStore(store, observe: \.viewState) { viewStore in
			NavigationStack {
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
				.toolbar(.visible, for: .navigationBar)
				.toolbar {
					if viewStore.shouldDisplayNavBar {
						ToolbarItem(placement: .navigationBarLeading) {
							CloseButton {
								viewStore.send(.view(.dismiss))
							}
						}
					}
				}
			}
		}
	}
}
