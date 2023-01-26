import FeaturePrelude

// MARK: - CreateAccountCoordinator.View
public extension CreateAccountCoordinator {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<CreateAccountCoordinator>

		public init(store: StoreOf<CreateAccountCoordinator>) {
			self.store = store
		}
	}
}

public extension CreateAccountCoordinator.View {
	var body: some View {
		SwitchStore(store.scope(state: \.root)) {
			CaseLet(
				state: /CreateAccountCoordinator.State.Root.nameNewEntity,
				action: { CreateAccountCoordinator.Action.child(.nameNewEntity($0)) },
				then: { NameNewEntity.View(store: $0) }
			)
			CaseLet(
				state: /CreateAccountCoordinator.State.Root.selectGenesisFactorSource,
				action: { CreateAccountCoordinator.Action.child(.selectGenesisFactorSource($0)) },
				then: { SelectGenesisFactorSource.View(store: $0) }
			)
			CaseLet(
				state: /CreateAccountCoordinator.State.Root.accountCompletion,
				action: { CreateAccountCoordinator.Action.child(.accountCompletion($0)) },
				then: { AccountCompletion.View(store: $0) }
			)
		}
	}
}
