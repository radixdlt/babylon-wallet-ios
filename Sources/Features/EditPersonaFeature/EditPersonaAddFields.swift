import FeaturePrelude

public struct EditPersonaAddFields: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let availableFields: [EditPersona.State.DynamicFieldID]
		var selectedFields: [EditPersona.State.DynamicFieldID]? = nil

		public init(
			excludedFieldIDs: [EditPersona.State.DynamicFieldID]
		) {
			self.availableFields = EditPersona.State.DynamicFieldID.allCases.filter { !excludedFieldIDs.contains($0) }
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case selectedFieldsChanged([EditPersona.State.DynamicFieldID]?)
		case addButtonTapped(NonEmptyArray<EditPersona.State.DynamicFieldID>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case addFields(NonEmptyArray<EditPersona.State.DynamicFieldID>)
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
