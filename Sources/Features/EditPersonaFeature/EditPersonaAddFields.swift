import FeaturePrelude

public struct EditPersonaAddFields: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let availableFields: [EditPersona.State.DynamicField]
		var chosenFields: [EditPersona.State.DynamicField]? = nil

		public init(
			excludedFields: [EditPersona.State.DynamicField]
		) {
			self.availableFields = EditPersona.State.DynamicField.allCases.filter { !excludedFields.contains($0) }
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case chosenFieldsChanged([EditPersona.State.DynamicField]?)
		case addButtonTapped(NonEmptyArray<EditPersona.State.DynamicField>)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .chosenFieldsChanged(chosenFields):
			state.chosenFields = chosenFields
			return .none

		case let .addButtonTapped(chosenFields):
			print(chosenFields)
			// TODO:
			return .none
		}
	}
}
