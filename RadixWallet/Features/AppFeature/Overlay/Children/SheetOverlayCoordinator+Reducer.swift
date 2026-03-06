import Foundation

// MARK: - SheetOverlayCoordinator
struct SheetOverlayCoordinator: FeatureReducer {
	struct State: Hashable, Identifiable {
		let id: UUID = .init()
		var root: Root.State

		init(root: Root.State) {
			self.root = root
		}
	}

	enum ViewAction: Equatable {
		case closeButtonTapped
	}

	@CasePathable
	enum ChildAction: Equatable {
		case root(Root.Action)
	}

	enum DelegateAction: Equatable {
		case dismiss
		case signing(Signing.DelegateAction)
		case derivePublicKeys(DerivePublicKeys.DelegateAction)
		case authorization(Authorization.DelegateAction)
		case spotCheck(SpotCheck.DelegateAction)
	}

	struct Root: Hashable, Reducer {
		@CasePathable
		enum State: Hashable {
			case infoLink(InfoLinkSheet.State)
			case signing(Signing.State)
			case derivePublicKeys(DerivePublicKeys.State)
			case authorization(Authorization.State)
			case spotCheck(SpotCheck.State)
		}

		@CasePathable
		enum Action: Equatable {
			case infoLink(InfoLinkSheet.Action)
			case signing(Signing.Action)
			case derivePublicKeys(DerivePublicKeys.Action)
			case authorization(Authorization.Action)
			case spotCheck(SpotCheck.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.infoLink, action: \.infoLink) {
				InfoLinkSheet()
			}
			Scope(state: \.signing, action: \.signing) {
				Signing()
			}
			Scope(state: \.derivePublicKeys, action: \.derivePublicKeys) {
				DerivePublicKeys()
			}
			Scope(state: \.authorization, action: \.authorization) {
				Authorization()
			}
			Scope(state: \.spotCheck, action: \.spotCheck) {
				SpotCheck()
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

		case let .root(.derivePublicKeys(.delegate(action))):
			.send(.delegate(.derivePublicKeys(action)))

		case let .root(.authorization(.delegate(action))):
			.send(.delegate(.authorization(action)))

		case let .root(.spotCheck(.delegate(action))):
			.send(.delegate(.spotCheck(action)))

		default:
			.none
		}
	}
}
