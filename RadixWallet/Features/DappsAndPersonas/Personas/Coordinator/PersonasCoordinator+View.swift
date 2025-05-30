import ComposableArchitecture
import SwiftUI

// MARK: - PersonasCoordinator.View
extension PersonasCoordinator {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<PersonasCoordinator>

		init(store: StoreOf<PersonasCoordinator>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			PersonaList.View(store: store.personaList)
				.onAppear { store.send(.view(.appeared)) }
				.destinations(with: store)
		}
	}
}

extension StoreOf<PersonasCoordinator> {
	var destination: PresentationStoreOf<PersonasCoordinator.Destination> {
		func scopeState(state: State) -> PresentationState<PersonasCoordinator.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}

	var personaList: StoreOf<PersonaList> {
		scope(state: \.personaList) { .child(.personaList($0)) }
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<PersonasCoordinator>) -> some View {
		let destinationStore = store.destination
		return createPersonaCoordinator(with: destinationStore)
			.personaDetails(with: destinationStore)
			.securityCenter(with: destinationStore)
	}

	private func createPersonaCoordinator(with destinationStore: PresentationStoreOf<PersonasCoordinator.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.createPersonaCoordinator, action: \.createPersonaCoordinator)) {
			CreatePersonaCoordinator.View(store: $0)
		}
	}

	private func personaDetails(with destinationStore: PresentationStoreOf<PersonasCoordinator.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.personaDetails, action: \.personaDetails)) {
			PersonaDetails.View(store: $0)
		}
	}

	private func securityCenter(with destinationStore: PresentationStoreOf<PersonasCoordinator.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.securityCenter, action: \.securityCenter)) {
			SecurityCenter.View(store: $0)
		}
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
	static let previewValue: Self = .init()
}
#endif
