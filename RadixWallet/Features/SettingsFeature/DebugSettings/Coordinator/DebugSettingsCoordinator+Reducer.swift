import ComposableArchitecture
import SwiftUI

public struct DebugSettingsCoordinator: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	public init() {}

	// MARK: State

	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destination.State?

		public init() {}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case factorSourcesButtonTapped
		case debugInspectProfileButtonTapped
		case debugUserDefaultsContentsButtonTapped
		case debugTestKeychainButtonTapped
		case debugKeychainContentsButtonTapped
		case securityStructureConfigsButtonTapped
		case dappLinkingDelayTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case profileToDebugLoaded(Profile)
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case debugUserDefaultsContents(DebugUserDefaultsContents.State)
			case debugInspectProfile(DebugInspectProfile.State)
			case debugManageFactorSources(DebugManageFactorSources.State)
			#if DEBUG
			case debugKeychainTest(DebugKeychainTest.State)
			case debugKeychainContents(DebugKeychainContents.State)
			#endif // DEBUG
			case securityStructureConfigs(SecurityStructureConfigurationListCoordinator.State)
			case dappLinkingDelay(DappLinkingDelay.State)
		}

		public enum Action: Sendable, Equatable {
			case debugUserDefaultsContents(DebugUserDefaultsContents.Action)
			case debugInspectProfile(DebugInspectProfile.Action)
			#if DEBUG
			case debugKeychainTest(DebugKeychainTest.Action)
			case debugKeychainContents(DebugKeychainContents.Action)
			#endif // DEBUG
			case debugManageFactorSources(DebugManageFactorSources.Action)
			case securityStructureConfigs(SecurityStructureConfigurationListCoordinator.Action)
			case dappLinkingDelay(DappLinkingDelay.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.debugUserDefaultsContents, action: /Action.debugUserDefaultsContents) {
				DebugUserDefaultsContents()
			}
			Scope(state: /State.debugInspectProfile, action: /Action.debugInspectProfile) {
				DebugInspectProfile()
			}
			#if DEBUG
			Scope(state: /State.debugKeychainTest, action: /Action.debugKeychainTest) {
				DebugKeychainTest()
			}
			Scope(state: /State.debugKeychainContents, action: /Action.debugKeychainContents) {
				DebugKeychainContents()
			}
			#endif // DEBUG
			Scope(state: /State.debugManageFactorSources, action: /Action.debugManageFactorSources) {
				DebugManageFactorSources()
			}
			Scope(state: /State.securityStructureConfigs, action: /Action.securityStructureConfigs) {
				SecurityStructureConfigurationListCoordinator()
			}
			Scope(state: /State.dappLinkingDelay, action: /Action.dappLinkingDelay) {
				DappLinkingDelay()
			}
		}
	}

	// MARK: Reducer

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dismiss) var dismiss
	@Dependency(\.userDefaults) var userDefaults

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .factorSourcesButtonTapped:
			state.destination = .debugManageFactorSources(.init())
			return .none

		case .debugInspectProfileButtonTapped:
			return .run { send in
				let snapshot = await appPreferencesClient.extractProfileSnapshot()
				guard let profile = try? Profile(snapshot: snapshot) else { return }
				await send(.internal(.profileToDebugLoaded(profile)))
			}

		case .debugTestKeychainButtonTapped:
			#if DEBUG
			state.destination = .debugKeychainTest(.init())
			#endif // DEBUG
			return .none

		case .debugKeychainContentsButtonTapped:
			#if DEBUG
			state.destination = .debugKeychainContents(.init())
			#endif // DEBUG
			return .none

		case .securityStructureConfigsButtonTapped:
			state.destination = .securityStructureConfigs(.init())
			return .none

		case .debugUserDefaultsContentsButtonTapped:
			state.destination = .debugUserDefaultsContents(.init())
			return .none
		case .dappLinkingDelayTapped:
			state.destination = .dappLinkingDelay(.init(delayInSeconds: userDefaults.getDappLinkingDelay()))
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .profileToDebugLoaded(profile):
			state.destination = .debugInspectProfile(.init(profile: profile))
			return .none
		}
	}
}
