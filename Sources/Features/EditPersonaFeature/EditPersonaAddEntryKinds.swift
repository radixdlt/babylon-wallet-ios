import FeaturePrelude

public struct EditPersonaAddEntryKinds: Sendable, FeatureReducer {
	public typealias EntryKind = EditPersona.State.DynamicFieldID

	public struct State: Sendable, Hashable {
		let availableEntryKinds: [EntryKind]
		var selectedEntryKinds: [EntryKind]? = nil

		public init(excludedEntryKinds: [EntryKind]) {
			self.availableEntryKinds = EditPersona.State.DynamicFieldID.supportedKinds
				.filter { !excludedEntryKinds.contains($0) }
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
		case selectedEntryKindsChanged([EntryKind]?)
		case addButtonTapped([EntryKind])
	}

	public enum DelegateAction: Sendable, Equatable {
		case addEntryKinds([EntryKind])
	}

	@Dependency(\.dismiss) var dismiss

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return .run { _ in await dismiss() }

		case let .selectedEntryKindsChanged(selectedEntryKinds):
			state.selectedEntryKinds = selectedEntryKinds
			return .none

		case let .addButtonTapped(selectedEntryKinds):
			return .send(.delegate(.addEntryKinds(selectedEntryKinds)))
		}
	}
}
