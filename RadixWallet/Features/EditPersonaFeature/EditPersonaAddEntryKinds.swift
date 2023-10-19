import ComposableArchitecture
import SwiftUI
public typealias EntryKind = PersonaData.Entry.Kind

// MARK: - EditPersonaAddEntryKinds
public struct EditPersonaAddEntryKinds: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let availableEntryKinds: [EntryKind]
		var selectedEntryKinds: [EntryKind]? = nil

		public init(excludedEntryKinds: [EntryKind]) {
			self.availableEntryKinds = EntryKind.supportedKinds
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

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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
