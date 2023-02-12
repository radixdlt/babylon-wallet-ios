import CreateEntityFeature
import FeaturePrelude

// MARK: - NewProfileThenAccountCoordinator.View
extension NewProfileThenAccountCoordinator {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NewProfileThenAccountCoordinator>

		public init(store: StoreOf<NewProfileThenAccountCoordinator>) {
			self.store = store
		}
	}
}

extension NewProfileThenAccountCoordinator.View {
	public var body: some View {
		SwitchStore(store.scope(state: \.step)) {
			CaseLet(
				state: /NewProfileThenAccountCoordinator.State.Step.newProfile,
				action: { NewProfileThenAccountCoordinator.Action.child(.newProfile($0)) },
				then: { NewProfile.View(store: $0) }
			)
			CaseLet(
				state: /NewProfileThenAccountCoordinator.State.Step.createAccountCoordinator,
				action: { NewProfileThenAccountCoordinator.Action.child(.createAccountCoordinator($0)) },
				then: { CreateAccountCoordinator.View(store: $0) }
			)
		}
	}
}

// MARK: - NewProfileThenAccountCoordinator.View.ViewState
extension NewProfileThenAccountCoordinator.View {
	struct ViewState: Equatable {
		init(state: NewProfileThenAccountCoordinator.State) {
			// TODO: implement
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - NewProfileThenAccountCoordinator_Preview
struct NewProfileThenAccountCoordinator_Preview: PreviewProvider {
	static var previews: some View {
		NewProfileThenAccountCoordinator.View(
			store: .init(
				initialState: .previewValue,
				reducer: NewProfileThenAccountCoordinator()
			)
		)
	}
}
#endif
