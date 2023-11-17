import ComposableArchitecture
import SwiftUI

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
			.onAppear { store.send(.view(.appeared)) }
			.destinations(with: store)
		}
	}
}

extension StoreOf<PersonasCoordinator> {
	var destination: PresentationStoreOf<PersonasCoordinator.Destination_> {
		scope(state: \.$destination) { .destination($0) }
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<PersonasCoordinator>) -> some View {
		let destinationStore = store.destination
		return createPersonaCoordinator(with: destinationStore)
			.personaDetails(with: destinationStore)
	}

	private func createPersonaCoordinator(with destinationStore: PresentationStoreOf<PersonasCoordinator.Destination_>) -> some View {
		sheet(
			store: destinationStore,
			state: /PersonasCoordinator.Destination_.State.createPersonaCoordinator,
			action: PersonasCoordinator.Destination_.Action.createPersonaCoordinator,
			content: { CreatePersonaCoordinator.View(store: $0) }
		)
	}

	private func personaDetails(with destinationStore: PresentationStoreOf<PersonasCoordinator.Destination_>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /PersonasCoordinator.Destination_.State.personaDetails,
			action: PersonasCoordinator.Destination_.Action.personaDetails,
			destination: { PersonaDetails.View(store: $0) }
		)
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

// MARK: - PersonasCoordinator_Preview
struct PersonasCoordinator_Preview: PreviewProvider {
	static var previews: some View {
		PersonasCoordinator.View(
			store: .init(
				initialState: .previewValue,
				reducer: PersonasCoordinator.init
			)
		)
	}
}

extension PersonasCoordinator.State {
	public static let previewValue: Self = .init()
}
#endif
