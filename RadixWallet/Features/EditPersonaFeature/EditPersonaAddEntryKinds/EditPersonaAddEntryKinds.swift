import ComposableArchitecture
import SwiftUI

typealias EntryKind = PersonaData.Entry.Kind

// MARK: - EditPersonaAddEntryKinds
struct EditPersonaAddEntryKinds: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let availableEntryKinds: [EntryKind]
		var selectedEntryKinds: [EntryKind]? = nil

		init(excludedEntryKinds: [EntryKind]) {
			self.availableEntryKinds = EntryKind.supportedKinds
				.filter { !excludedEntryKinds.contains($0) }
		}
	}

	enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
		case selectedEntryKindsChanged([EntryKind]?)
		case addButtonTapped([EntryKind])
	}

	enum DelegateAction: Sendable, Equatable {
		case addEntryKinds([EntryKind])
	}

	@Dependency(\.dismiss) var dismiss

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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
