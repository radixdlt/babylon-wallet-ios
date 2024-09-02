import Foundation

// MARK: - SheetOverlayCoordinator
public struct SheetOverlayCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var root: Root.State

		public init(root: Root.State) {
			self.root = root
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case root(Root.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	public struct Root: Sendable, Hashable, Reducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case infoLink(InfoLinkSheet.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case infoLink(InfoLinkSheet.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: \.infoLink, action: \.infoLink) {
				InfoLinkSheet()
			}
		}
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.root, action: \.child.root) {
			Root()
		}
		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			.send(.delegate(.dismiss))
		}
	}
}
