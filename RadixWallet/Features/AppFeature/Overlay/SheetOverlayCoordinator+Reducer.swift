import Foundation

// MARK: - SheetOverlayCoordinator
struct SheetOverlayCoordinator: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var root: Root.State

		init(root: Root.State) {
			self.root = root
		}
	}

	enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case root(Root.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	struct Root: Sendable, Hashable, Reducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case infoLink(InfoLinkSheet.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case infoLink(InfoLinkSheet.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.infoLink, action: \.infoLink) {
				InfoLinkSheet()
			}
		}
	}

	init() {}

	var body: some ReducerOf<Self> {
		Scope(state: \.root, action: \.child.root) {
			Root()
		}
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			.send(.delegate(.dismiss))
		}
	}
}
