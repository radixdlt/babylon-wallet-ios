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
		case closeButtonTapped
		case selectedFieldsChanged([EditPersona.State.DynamicFieldID]?)
		case addButtonTapped([EditPersona.State.DynamicFieldID])
	}

	public enum DelegateAction: Sendable, Equatable {
		case addFields([EditPersona.State.DynamicFieldID])
	}

	@Dependency(\.dismiss) var dismiss

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return .run { _ in await dismiss() }

		case let .selectedFieldsChanged(selectedFields):
			state.selectedFields = selectedFields
			return .none

		case let .addButtonTapped(selectedFields):
			return .send(.delegate(.addFields(selectedFields)))
		}
	}
}
