import ComposableArchitecture
import SwiftUI

struct EditPersonaEntry<ContentReducer>: FeatureReducer where ContentReducer: FeatureReducer & EmptyInitializable {
	struct State: Sendable, Hashable {
		typealias ID = EntryKind
		let kind: EntryKind
		let isRequestedByDapp: Bool

		var content: ContentReducer.State
	}

	enum ChildAction: Sendable, Equatable {
		case content(ContentReducer.Action)
	}

	enum ViewAction: Sendable, Equatable {
		case deleteButtonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case delete
	}

	var body: some ReducerOf<Self> {
		Reduce(core)

		Scope(state: \.content, action: /Action.child .. ChildAction.content) {
			ContentReducer()
		}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .deleteButtonTapped:
			.send(.delegate(.delete))
		}
	}
}
