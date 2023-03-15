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

		public var body: some SwiftUI.View {
			ZStack {
				PersonaList.View(
					store: store.scope(
						state: \.personaList,
						action: { .child(.personaList($0)) }
					)
				)
				.onAppear { ViewStore(store.stateless).send(.view(.appeared)) }

				IfLetStore(
					store.scope(
						state: \.createPersonaCoordinator,
						action: { .child(.createPersonaCoordinator($0)) }
					),
					then: { CreatePersonaCoordinator.View(store: $0) }
				)
			}
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
