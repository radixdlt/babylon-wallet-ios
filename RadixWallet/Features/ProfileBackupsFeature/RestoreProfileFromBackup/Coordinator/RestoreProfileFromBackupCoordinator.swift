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
		public var selectBackup = SelectBackup.State()
		public var profileSelection: ProfileSelection?

		@PresentationState
		public var destination: Destination.State?
	}

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case importMnemonicsFlow(ImportMnemonicsFlowCoordinator.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case importMnemonicsFlow(ImportMnemonicsFlowCoordinator.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: \.importMnemonicsFlow, action: \.importMnemonicsFlow) {
				ImportMnemonicsFlowCoordinator()
			}
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case startImportMnemonicsFlow(Profile)
	}

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case selectBackup(SelectBackup.Action)
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
		Scope(state: \.selectBackup, action: \.child.selectBackup) {
			SelectBackup()
		}
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .selectBackup(.delegate(.selectedProfile(profile, containsLegacyP2PLinks))):
			state.profileSelection = .init(profile: profile, containsP2PLinks: containsLegacyP2PLinks)

			return .run { send in
				try? await clock.sleep(for: .milliseconds(300))
				_ = await radixConnectClient.loadP2PLinksAndConnectAll()
				await send(.internal(.startImportMnemonicsFlow(profile)))
			}

		case .selectBackup(.delegate(.backToStartOfOnboarding)):
			return .send(.delegate(.backToStartOfOnboarding))

		case .selectBackup(.delegate(.profileCreatedFromImportedBDFS)):
			return .send(.delegate(.profileCreatedFromImportedBDFS))

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .startImportMnemonicsFlow(profile):
			state.destination = .importMnemonicsFlow(.init(context: .fromOnboarding(profile: profile)))
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .importMnemonicsFlow(.delegate(.finishedImportingMnemonics(skipList, _, skippedMainBdfs))):
			loggerGlobal.notice("Starting import snapshot process...")
			guard let profileSelection = state.profileSelection else {
				preconditionFailure("Expected to have a profile")
			}
			return .run { send in
				loggerGlobal.notice("Importing snapshot...")

				let factorSourceIDs: Set<FactorSourceIDFromHash> = .init(
					profileSelection.profile.factorSources.compactMap { $0.extract(DeviceFactorSource.self) }.map(\.id)
				)
				try await transportProfileClient.importProfile(profileSelection.profile, factorSourceIDs, profileSelection.containsP2PLinks, skippedMainBdfs)

				await send(.delegate(.profileImported(
					skippedAnyMnemonic: !skipList.isEmpty
				)))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case let .importMnemonicsFlow(.delegate(.finishedEarly(didFail))):
			state.destination = nil
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
