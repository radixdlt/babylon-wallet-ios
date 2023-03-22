import FeaturePrelude

public struct EditPersonaAddFields: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let availableFields: [EditPersona.State.DynamicField]
		var selectedFields: [EditPersona.State.DynamicField]? = nil

		public init(
			excludedFieldIDs: [EditPersona.State.DynamicField]
		) {
			self.availableFields = EditPersona.State.DynamicField.allCases.filter { !excludedFieldIDs.contains($0) }
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case selectedFieldsChanged([EditPersona.State.DynamicField]?)
		case addButtonTapped(NonEmptyArray<EditPersona.State.DynamicField>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case addFields(NonEmptyArray<EditPersona.State.DynamicField>)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .selectedFieldsChanged(selectedFields):
			state.selectedFields = selectedFields
			return .none

		case let .addButtonTapped(selectedFields):
			return .send(.delegate(.addFields(selectedFields)))
		}
	}
}
