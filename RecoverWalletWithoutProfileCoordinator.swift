// MARK: - RecoverWalletWithoutProfileCoordinator

public struct RecoverWalletWithoutProfileCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
//		public var root: RecoverWalletWithoutProfileStart.State
		public var root: Path.State?
		public var path: StackState<Path.State> = .init()

		public init() {
			self.root = .recoverWalletWithoutProfileStart(.init())
			//            self.root = .init()
		}
	}

	public struct Path: Sendable, Hashable, Reducer {
		public enum State: Sendable, Hashable {
			case recoverWalletWithoutProfileStart(RecoverWalletWithoutProfileStart.State)
			case recoverWalletControlWithBDFSOnly(RecoverWalletControlWithBDFSOnly.State)
			case importMnemonic(ImportMnemonic.State)
		}

		public enum Action: Sendable, Equatable {
			case recoverWalletWithoutProfileStart(RecoverWalletWithoutProfileStart.Action)
			case recoverWalletControlWithBDFSOnly(RecoverWalletControlWithBDFSOnly.Action)
			case importMnemonic(ImportMnemonic.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.recoverWalletWithoutProfileStart, action: /Action.recoverWalletWithoutProfileStart) {
				RecoverWalletWithoutProfileStart()
			}
			Scope(state: /State.recoverWalletControlWithBDFSOnly, action: /Action.recoverWalletControlWithBDFSOnly) {
				RecoverWalletControlWithBDFSOnly()
			}
			Scope(state: /State.importMnemonic, action: /Action.importMnemonic) {
				ImportMnemonic()
			}
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case root(Path.Action)
		case path(StackActionOf<Path>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case backToStartOfOnboarding
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	@Dependency(\.dismiss) var dismiss
	public init() {}

	public var body: some ReducerOf<Self> {
		//        Scope(state: \.root, action: /Action.child .. ChildAction.root) {
		//            RecoverWalletWithoutProfileStart()
		//        }

		Reduce(core)
			.ifLet(\.root, action: /Action.child .. ChildAction.root) {
				Path()
			}
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
	}

	public func reduce(into _: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			.none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .root(.recoverWalletWithoutProfileStart(.delegate(.backToStartOfOnboarding))):
			//        case .root(.delegate(.backToStartOfOnboarding)):
			return .send(.delegate(.backToStartOfOnboarding))
		case .root(.recoverWalletWithoutProfileStart(.delegate(.dismiss))):
			//        case .root(.delegate(.dismiss)):
			return .run { _ in
				await dismiss()
			}
		case .root(.recoverWalletWithoutProfileStart(.delegate(.recoverWithBDFSOnly))):
			//        case .root(.delegate(.recoverWithBDFSOnly)):
			state.path.append(.recoverWalletControlWithBDFSOnly(.init()))
			return .none

		case .path(.element(_, action: .recoverWalletControlWithBDFSOnly(.delegate(.continue)))):
			state.path.append(.importMnemonic(.init(persistStrategy: nil)))
			return .none

		default: return .none
		}
	}
}
