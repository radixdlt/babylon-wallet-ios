import FeaturePrelude

// MARK: - CreateProfileCoordinator.View
public extension CreateProfileCoordinator {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<CreateProfileCoordinator>

		public init(store: StoreOf<CreateProfileCoordinator>) {
			self.store = store
		}
	}
}

public extension CreateProfileCoordinator.View {
	var body: some View {
		SwitchStore(store) {
			CaseLet(
				state: /CreateProfileCoordinator.State.importProfile,
				action: { CreateProfileCoordinator.Action.child(.importProfile($0)) },
				then: { ImportProfile.View(store: $0) }
			)
			CaseLet(
				state: /CreateProfileCoordinator.State.newProfile,
				action: { CreateProfileCoordinator.Action.child(.newProfile($0)) },
				then: { NewProfile.View(store: $0) }
			)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - CreateProfileCoordinator_Preview
struct CreateProfileCoordinator_Preview: PreviewProvider {
	static var previews: some View {
		CreateProfileCoordinator.View(
			store: .init(
				initialState: .previewValue,
				reducer: CreateProfileCoordinator()
			)
		)
	}
}
#endif
