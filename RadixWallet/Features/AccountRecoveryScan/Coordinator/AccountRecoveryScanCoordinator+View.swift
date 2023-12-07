// MARK: - AccountRecoveryScanCoordinator.View
public extension AccountRecoveryScanCoordinator {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<AccountRecoveryScanCoordinator>

		public init(store: StoreOf<AccountRecoveryScanCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			SwitchStore(store.scope(state: \.root, action: Action.child)) { state in
				switch state {
				case .accountRecoveryScanInProgress:
					CaseLet(
						/AccountRecoveryScanCoordinator.State.Root.accountRecoveryScanInProgress,
						action: AccountRecoveryScanCoordinator.ChildAction.accountRecoveryScanInProgress,
						then: { AccountRecoveryScanInProgress.View(store: $0) }
					)
				case .selectInactiveAccountsToAdd:
					CaseLet(
						/AccountRecoveryScanCoordinator.State.Root.selectInactiveAccountsToAdd,
						action: AccountRecoveryScanCoordinator.ChildAction.selectInactiveAccountsToAdd,
						then: { SelectInactiveAccountsToAdd.View(store: $0) }
					)
					.transition(.move(edge: .trailing))
				}
			}
		}
	}
}
