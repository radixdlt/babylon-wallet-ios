import FeaturePrelude

public struct EditPersonaAddFields: Sendable, FeatureReducer {
	public typealias EntryKind = EditPersona.State.DynamicFieldID.Kind

	public struct State: Sendable, Hashable {
		let availableFields: [EntryKind]
		var selectedFields: [EntryKind]? = nil

		public init(
			excludedFieldIDs: [EntryKind]
		) {
			self.availableFields = EditPersona.State.DynamicFieldID.supportedKinds.filter { !excludedFieldIDs.contains($0) }
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
		case selectedFieldsChanged([EntryKind]?)
		case addButtonTapped([EntryKind])
	}

	public enum DelegateAction: Sendable, Equatable {
		case addFields([EntryKind])
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
