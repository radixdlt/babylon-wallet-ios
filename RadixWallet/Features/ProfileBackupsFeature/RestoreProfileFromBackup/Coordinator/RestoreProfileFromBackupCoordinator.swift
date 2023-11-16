import ComposableArchitecture
import SwiftUI

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

	public struct Path: Sendable, Hashable, Reducer {
		public enum State: Sendable, Hashable {
			case selectBackup(SelectBackup.State)
			case importMnemonicsFlow(ImportMnemonicsFlowCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case selectBackup(SelectBackup.Action)
			case importMnemonicsFlow(ImportMnemonicsFlowCoordinator.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.selectBackup, action: /Action.selectBackup) {
				SelectBackup()
			}

			Scope(state: /State.importMnemonicsFlow, action: /Action.importMnemonicsFlow) {
				ImportMnemonicsFlowCoordinator()
			}
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case delayedAppendToPath(RestoreProfileFromBackupCoordinator.Path.State)
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
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.continuousClock) var clock
	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.root, action: /Action.child .. ChildAction.root) {
			Path()
		}

		Reduce(core)
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .delayedAppendToPath(destination):
			state.path.append(destination)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .root(.selectBackup(.delegate(.selectedProfileSnapshot(profileSnapshot, isInCloud)))):
			state.profileSelection = .init(snapshot: profileSnapshot, isInCloud: isInCloud)
			return .run { send in
				try? await clock.sleep(for: .milliseconds(300))
				await send(.internal(.delayedAppendToPath(
					.importMnemonicsFlow(.init(context: .fromOnboarding(profileSnapshot: profileSnapshot))
					))))
			}

		case let .path(.element(_, action: .importMnemonicsFlow(.delegate(.finishedImportingMnemonics(skipList, _, notYetSavedNewMainBDFS))))):
			loggerGlobal.notice("Starting import snapshot process...")
			guard let profileSelection = state.profileSelection else {
				preconditionFailure("Expected to have a profile")
				return .none
			}
			return .run { send in
				loggerGlobal.notice("Importing snapshot...")
				try await backupsClient.importSnapshot(profileSelection.snapshot, fromCloud: profileSelection.isInCloud)

				if let notYetSavedNewMainBDFS {
					try await factorSourcesClient.saveNewMainBDFS(notYetSavedNewMainBDFS)
				}

				await send(.delegate(.profileImported(
					skippedAnyMnemonic: !skipList.isEmpty
				)))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case let .path(.element(_, action: .importMnemonicsFlow(.delegate(.finishedEarly(didFail))))):
			state.path.removeLast()
			return didFail ? .send(.delegate(.failedToImportProfileDueToMnemonics)) : .none

		default:
			return .none
		}
	}
}
