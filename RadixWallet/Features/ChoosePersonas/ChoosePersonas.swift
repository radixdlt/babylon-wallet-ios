import ComposableArchitecture
import SwiftUI

// MARK: - ChoosePersonas
@Reducer
struct ChoosePersonas: FeatureReducer {
	@ObservableState
	struct State: Hashable {
		var availablePersonas: IdentifiedArrayOf<PersonaRow.State> = []
		var selectedPersonas: [PersonaRow.State]? = nil
		let selectionRequirement: SelectionRequirement
		var showSelectAllPersonas: Bool = false
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Equatable {
		case appeared
		case selectedPersonasChanged([PersonaRow.State]?)
	}

	enum InternalAction: Equatable {
		case personasLoaded(Personas)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.personasClient) var personasClient

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return loadPersonas()

		case let .selectedPersonasChanged(selectedPersonas):
			state.selectedPersonas = selectedPersonas
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .personasLoaded(personas):
			state.availablePersonas = personas.map {
				PersonaRow.State(persona: $0, lastLogin: nil)
			}
			.asIdentified()
			return .none
		}
	}

	func loadPersonas() -> Effect<Action> {
		.run { send in
			let personas = try await personasClient.getPersonas()
			await send(.internal(.personasLoaded(personas)))
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}
}
