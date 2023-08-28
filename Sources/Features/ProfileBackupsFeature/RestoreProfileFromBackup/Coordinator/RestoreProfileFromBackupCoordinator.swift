import FeaturePrelude

// MARK: - ProfileSelection
public struct ProfileSelection: Sendable, Hashable {
	public let snapshot: ProfileSnapshot
	public let isInCloud: Bool
}

// MARK: - RestoreProfileFromBackupCoordinator
public struct RestoreProfileFromBackupCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var root: Path.State
		public var path: StackState<Path.State> = .init()
		public var profileSelection: ProfileSelection?

		public init() {
			self.root = .selectBackup(.init())
		}
	}

	public struct Path: Sendable, Hashable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case selectBackup(SelectBackup.State)
			case importMnemonicsFlow(ImportMnemonicsFlowCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case selectBackup(SelectBackup.Action)
			case importMnemonicsFlow(ImportMnemonicsFlowCoordinator.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.selectBackup, action: /Action.selectBackup) {
				SelectBackup()
			}

			Scope(state: /State.importMnemonicsFlow, action: /Action.importMnemonicsFlow) {
				ImportMnemonicsFlowCoordinator()
			}
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case root(Path.Action)
		case path(StackActionOf<Path>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case profileImported(skippedAnyMnemonic: Bool)
		case failedToImportProfileDueToMnemonics
	}

	@Dependency(\.backupsClient) var backupsClient
	@Dependency(\.errorQueue) var errorQueue
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.root, action: /Action.child .. ChildAction.root) {
			Path()
		}

		Reduce(core)
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .root(.selectBackup(.delegate(.selectedProfileSnapshot(profileSnapshot, isInCloud)))):
			state.profileSelection = .init(snapshot: profileSnapshot, isInCloud: isInCloud)
			state.path.append(.importMnemonicsFlow(.init(profileSnapshot: profileSnapshot)))
			return .none

		case let .path(.element(_, action: .importMnemonicsFlow(.delegate(.finishedImportingMnemonics(skippedAnyMnemonic))))):
			loggerGlobal.notice("Starting import snapshot process...")
			guard let profileSelection = state.profileSelection else {
				preconditionFailure("Expected to have a profile")
				return .none
			}
			return .run { send in
				loggerGlobal.notice("Importing snapshot...")
				try await backupsClient.importSnapshot(profileSelection.snapshot, fromCloud: profileSelection.isInCloud)
				await send(.delegate(.profileImported(skippedAnyMnemonic: skippedAnyMnemonic)))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case .path(.element(_, action: .importMnemonicsFlow(.delegate(.failedToImportAllRequiredMnemonics)))):
			state.path.removeLast()
			return .send(.delegate(.failedToImportProfileDueToMnemonics))

		case .path(.element(_, action: .importMnemonicsFlow(.delegate(.closeButtonTapped)))):
			state.path.removeLast()
			return .none

		default:
			return .none
		}
	}
}
