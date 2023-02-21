import CreateEntityFeature
import FeaturePrelude

// MARK: - PersonasCoordinator.View
extension PersonasCoordinator {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<PersonasCoordinator>

		public init(store: StoreOf<PersonasCoordinator>) {
			self.store = store
		}
	}
}

extension PersonasCoordinator.View {
	public var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ForceFullScreen {
				ZStack {
					PersonaList.View(
						store: store.scope(
							state: \.personaList,
							action: { .child(.personaList($0)) }
						)
					)
					.onAppear { viewStore.send(.appeared) }

					IfLetStore(
						store.scope(
							state: \.createPersonaCoordinator,
							action: { .child(.createPersonaCoordinator($0)) }
						),
						then: { CreatePersonaCoordinator.View(store: $0) }
					)
					.zIndex(1)
				}
			}
		}
	}
}

// MARK: - PersonasCoordinator.View.ViewState
extension PersonasCoordinator.View {
	struct ViewState: Equatable {
		init(state: PersonasCoordinator.State) {
			// TODO: implement
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - PersonasCoordinator_Preview
struct PersonasCoordinator_Preview: PreviewProvider {
	static var previews: some View {
		PersonasCoordinator.View(
			store: .init(
				initialState: .previewValue,
				reducer: PersonasCoordinator()
			)
		)
	}
}
#endif
