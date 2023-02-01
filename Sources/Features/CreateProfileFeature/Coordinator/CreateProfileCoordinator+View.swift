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
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			// TODO: implement
			Text("Implement: CreateProfileCoordinator")
				.background(Color.yellow)
				.foregroundColor(.red)
				.onAppear { viewStore.send(.appeared) }
		}
	}
}

// MARK: - CreateProfileCoordinator.View.ViewState
extension CreateProfileCoordinator.View {
	struct ViewState: Equatable {
		init(state: CreateProfileCoordinator.State) {
			// TODO: implement
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
