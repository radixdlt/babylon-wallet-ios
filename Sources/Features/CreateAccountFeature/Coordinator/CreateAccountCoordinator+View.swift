import FeaturePrelude
import SwiftUI

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
				state: /CreateAccountCoordinator.State.Root.createAccount,
				action: { CreateAccountCoordinator.Action.child(.createAccount($0)) },
				then: { CreateAccount.View(store: $0) }
			)
			CaseLet(
				state: /CreateAccountCoordinator.State.Root.accountCompletion,
				action: { CreateAccountCoordinator.Action.child(.accountCompletion($0)) },
				then: { AccountCompletion.View(store: $0) }
			)
		}
	}
}
