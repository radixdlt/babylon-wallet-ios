import Foundation

// MARK: - SheetBehavior
public enum SheetBehavior: Sendable {
	case enqueue
	case replace
}

// MARK: - SheetOverlayCoordinator
public struct SheetOverlayCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public let id: UUID = .init()
		public var root: Root.State

		public init(root: Root.State) {
			self.root = root
		}
	}

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case root(Root.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case infoLink(InfoLinkSheet.DelegateAction)
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

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		// Forward all delegate actions, re-wrapped
		case let .root(.infoLink(.delegate(action))):
			.send(.delegate(.infoLink(action)))

		default:
			.none
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
		case closeButtonTapped
	}

	public enum DelegateAction: Equatable, Sendable {
		case dismiss
	}

	@Dependency(\.overlayWindowClient) var overlayWindowClient

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .infoLinkTapped(infoLink):
			overlayWindowClient.showInfoLink(infoLink)
			return .none
		case .closeButtonTapped:
			return .run { send in
				await send(.delegate(.dismiss))
			}
		}
	}
}
