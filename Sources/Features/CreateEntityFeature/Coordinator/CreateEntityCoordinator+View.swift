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

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState) { viewStore in
				NavigationStack {
					SwitchStore(store.scope(state: \.step)) {
						CaseLet(
							state: /CreateEntityCoordinator.State.Step.step1_nameNewEntity,
							action: { CreateEntityCoordinator.Action.child(.step1_nameNewEntity($0)) },
							then: { NameNewEntity.View(store: $0) }
						)
						CaseLet(
							state: /CreateEntityCoordinator.State.Step.step2_selectGenesisFactorSource,
							action: { CreateEntityCoordinator.Action.child(.step2_selectGenesisFactorSource($0)) },
							then: { SelectGenesisFactorSource.View(store: $0) }
						)
						CaseLet(
							state: /CreateEntityCoordinator.State.Step.step3_creationOfEntity,
							action: { CreateEntityCoordinator.Action.child(.step3_creationOfEntity($0)) },
							then: { CreationOfEntity.View(store: $0) }
						)
						CaseLet(
							state: /CreateEntityCoordinator.State.Step.step4_completion,
							action: { CreateEntityCoordinator.Action.child(.step4_completion($0)) },
							then: { NewEntityCompletion.View(store: $0) }
						)
					}
					#if os(iOS)
					.toolbar {
						if viewStore.shouldDisplayNavBar {
							ToolbarItem(placement: .navigationBarLeading) {
								CloseButton {
									viewStore.send(.view(.closeButtonTapped))
								}
							}
						}
					}
					#endif
				}
			}
		}
	}
}
