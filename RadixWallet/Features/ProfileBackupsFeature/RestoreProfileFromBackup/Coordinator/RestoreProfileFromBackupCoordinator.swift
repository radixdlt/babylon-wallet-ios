import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - ProfileSelection
public struct ProfileSelection: Sendable, Hashable {
	public let profile: Profile
	public let containsP2PLinks: Bool
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
		@CasePathable
		public enum State: Sendable, Hashable {
			case selectBackup(SelectBackup.State)
			case importMnemonicsFlow(ImportMnemonicsFlowCoordinator.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case selectBackup(SelectBackup.Action)
			case importMnemonicsFlow(ImportMnemonicsFlowCoordinator.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: \.selectBackup, action: \.selectBackup) {
				SelectBackup()
			}
			Scope(state: \.importMnemonicsFlow, action: \.importMnemonicsFlow) {
				ImportMnemonicsFlowCoordinator()
			}
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case delayedAppendToPath(RestoreProfileFromBackupCoordinator.Path.State)
	}

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case root(Path.Action)
		case path(StackActionOf<Path>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case profileImported(skippedAnyMnemonic: Bool)
		case failedToImportProfileDueToMnemonics
		case backToStartOfOnboarding
		case profileCreatedFromImportedBDFS
	}

	@Dependency(\.transportProfileClient) var transportProfileClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.continuousClock) var clock
	@Dependency(\.radixConnectClient) var radixConnectClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.root, action: \.child.root) {
			Path()
		}

		Reduce(core)
			.forEach(\.path, action: \.child.path) {
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
		case let .root(.selectBackup(.delegate(.selectedProfile(profile, containsLegacyP2PLinks)))):
			state.profileSelection = .init(profile: profile, containsP2PLinks: containsLegacyP2PLinks)

			return .run { send in
				try? await clock.sleep(for: .milliseconds(300))
				_ = await radixConnectClient.loadP2PLinksAndConnectAll()
				await send(.internal(.delayedAppendToPath(
					.importMnemonicsFlow(.init(context: .fromOnboarding(profile: profile)))
				)))
			}

		case .root(.selectBackup(.delegate(.backToStartOfOnboarding))):
			return .send(.delegate(.backToStartOfOnboarding))

		case .root(.selectBackup(.delegate(.profileCreatedFromImportedBDFS))):
			return .send(.delegate(.profileCreatedFromImportedBDFS))

		case let .path(.element(_, action: .importMnemonicsFlow(.delegate(.finishedImportingMnemonics(skipList, _, notYetSavedNewMainBDFS))))):
			loggerGlobal.notice("Starting import snapshot process...")
			guard let profileSelection = state.profileSelection else {
				preconditionFailure("Expected to have a profile")
			}
			return .run { send in
				loggerGlobal.notice("Importing snapshot...")

				let factorSourceIDs: Set<FactorSourceIDFromHash> = .init(
					profileSelection.profile.factorSources.compactMap { $0.extract(DeviceFactorSource.self) }.map(\.id)
				)
				try await transportProfileClient.importProfile(profileSelection.profile, factorSourceIDs, profileSelection.containsP2PLinks)

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
			return .run { send in
				await radixConnectClient.disconnectAll()
				if didFail {
					await send(.delegate(.failedToImportProfileDueToMnemonics))
				}
			}

		default:
			return .none
		}
	}
}
