import ComposableArchitecture
import CreateAccountFeature
import DesignSystem
import ImportProfileFeature
import SwiftUI

// MARK: - Onboarding.View
public extension Onboarding {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<Onboarding>

		public init(store: StoreOf<Onboarding>) {
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
				then: { ImportProfile.View(store: $0) }
			)
			CaseLet(
				state: /Onboarding.State.Root.createAccount,
				action: { Onboarding.Action.createAccount($0) },
				then: { CreateAccount.View(store: $0) }
			)
		}
	}
}

#if DEBUG
struct Onboarding_Preview: PreviewProvider {
	static var previews: some View {
		Onboarding.View(
			store: .init(
				initialState: .previewValue,
				reducer: Onboarding()
			)
		)
	}
}
#endif
