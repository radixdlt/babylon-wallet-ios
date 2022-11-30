import ComposableArchitecture
import CreateAccountFeature
import DesignSystem
import ImportProfileFeature
import SwiftUI

// MARK: - Onboarding.View
public extension Onboarding {
	@MainActor
	struct View: SwiftUI.View {
		private let store: Store<State, Action>

		public init(store: Store<State, Action>) {
			self.store = store
		}
	}
}

public extension Onboarding.View {
	var body: some View {
        SwitchStore(store.scope(state: \.root)) {
            CaseLet(
                state: /Onboarding.State.Root.importProfile,
                action: { Onboarding.Action.importProfile($0) },
                then: ImportProfile.View.init(store:)
            )
            CaseLet(
                state: /Onboarding.State.Root.createAccount,
                action: { Onboarding.Action.createAccount($0) },
                then: CreateAccount.View.init(store:)
            )
        }
	}
}
