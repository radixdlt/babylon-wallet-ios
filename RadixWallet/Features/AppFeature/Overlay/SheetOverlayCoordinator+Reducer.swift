import Foundation

// MARK: - SheetOverlayCoordinator
struct SheetOverlayCoordinator: Sendable, FeatureReducer {
	struct State: Sendable, Hashable, Identifiable {
		let id: UUID = .init()
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
		case signing(Signing.DelegateAction)
		case newSigning(NewSigning.DelegateAction)
	}

	struct Root: Sendable, Hashable, Reducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case infoLink(InfoLinkSheet.State)
			case signing(Signing.State)
			case newSigning(NewSigning.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case infoLink(InfoLinkSheet.Action)
			case signing(Signing.Action)
			case newSigning(NewSigning.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.infoLink, action: \.infoLink) {
				InfoLinkSheet()
			}
			Scope(state: \.signing, action: \.signing) {
				Signing()
			}
			Scope(state: \.newSigning, action: \.newSigning) {
				NewSigning()
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

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		// Forward all delegate actions, re-wrapped
		case let .root(.signing(.delegate(action))):
			.send(.delegate(.signing(action)))

		case let .root(.newSigning(.delegate(action))):
			.send(.delegate(.newSigning(action)))

		default:
			.none
		}
	}
}
