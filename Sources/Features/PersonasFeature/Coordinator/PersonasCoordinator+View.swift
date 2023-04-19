import CreateEntityFeature
import FeaturePrelude
import PersonaDetailsFeature

// MARK: - PersonasCoordinator.View
extension PersonasCoordinator {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<PersonasCoordinator>

		public init(store: StoreOf<PersonasCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			PersonaList.View(
				store: store.scope(
					state: \.personaList,
					action: { .child(.personaList($0)) }
				)
			)
			.task {
				await ViewStore(store).send(.view(.task)).finish()
			}
			.onAppear { ViewStore(store.stateless).send(.view(.appeared)) }
			.sheet(
				store: store.scope(
					state: \.$createPersonaCoordinator,
					action: { .child(.createPersonaCoordinator($0)) }
				),
				content: { CreatePersonaCoordinator.View(store: $0) }
			)
			.sheet(
				store: store.scope(
					state: \.$personaDetails,
					action: { .child(.personaDetails($0)) }
				),
				content: { PersonaDetails.View(store: $0) }
			)
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

extension PersonasCoordinator.State {
	public static let previewValue: Self = .init()
}
#endif
