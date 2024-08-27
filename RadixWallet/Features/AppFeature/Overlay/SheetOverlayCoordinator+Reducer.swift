import Foundation

// MARK: - SheetOverlayCoordinator
public struct SheetOverlayCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public let id: UUID = .init()
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

// MARK: - InfoLinkSheet
public struct InfoLinkSheet: FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public let id = UUID()
		public let image: ImageAsset?
		public let text: String
	}

	public enum ViewAction: Equatable, Sendable {
		case infoLinkTapped(OverlayWindowClient.GlossaryItem)
	}

	@Dependency(\.overlayWindowClient) var overlayWindowClient

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .infoLinkTapped(infoLink):
			overlayWindowClient.showInfoLink(infoLink)
			return .none
		}
	}
}