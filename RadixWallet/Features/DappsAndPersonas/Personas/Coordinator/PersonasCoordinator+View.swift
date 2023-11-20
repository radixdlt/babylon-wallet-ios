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
			.exportMnemonic(with: destinationStore)
	}

	private func createPersonaCoordinator(with destinationStore: PresentationStoreOf<PersonasCoordinator.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /PersonasCoordinator.Destination.State.createPersonaCoordinator,
			action: PersonasCoordinator.Destination.Action.createPersonaCoordinator,
			content: { CreatePersonaCoordinator.View(store: $0) }
		)
	}

	private func personaDetails(with destinationStore: PresentationStoreOf<PersonasCoordinator.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /PersonasCoordinator.Destination.State.personaDetails,
			action: PersonasCoordinator.Destination.Action.personaDetails,
			destination: { PersonaDetails.View(store: $0) }
		)
	}

	@MainActor
	private func exportMnemonic(with destinationStore: PresentationStoreOf<PersonasCoordinator.Destination>) -> some SwiftUI.View {
		sheet(
			store: destinationStore,
			state: /PersonasCoordinator.Destination.State.exportMnemonic,
			action: PersonasCoordinator.Destination.Action.exportMnemonic,
			content: { childStore in
				NavigationStack {
					ExportMnemonic.View(store: childStore)
				}
			}
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
