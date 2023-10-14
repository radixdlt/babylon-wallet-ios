import DebugInspectProfileFeature
import FeaturePrelude
import SecurityStructureConfigurationListFeature

public struct DebugSettingsCoordinator: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	public init() {}

	// MARK: State

	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destinations.State?

		public init() {}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case factorSourcesButtonTapped
		case debugInspectProfileButtonTapped
		case debugUserDefaultsContentsButtonTapped
		case debugTestKeychainButtonTapped
		case securityStructureConfigsButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case profileToDebugLoaded(Profile)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public struct Destinations: Sendable, Reducer {
		public enum State: Sendable, Hashable {
			case debugUserDefaultsContents(DebugUserDefaultsContents.State)
			case debugInspectProfile(DebugInspectProfile.State)
			case debugManageFactorSources(DebugManageFactorSources.State)
			#if DEBUG
			case debugKeychainTest(DebugKeychainTest.State)
			#endif // DEBUG
			case securityStructureConfigs(SecurityStructureConfigurationListCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case debugUserDefaultsContents(DebugUserDefaultsContents.Action)
			case debugInspectProfile(DebugInspectProfile.Action)
			#if DEBUG
			case debugKeychainTest(DebugKeychainTest.Action)
			#endif // DEBUG
			case debugManageFactorSources(DebugManageFactorSources.Action)
			case securityStructureConfigs(SecurityStructureConfigurationListCoordinator.Action)
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
			#endif // DEBUG
			Scope(state: /State.debugManageFactorSources, action: /Action.debugManageFactorSources) {
				DebugManageFactorSources()
			}
			Scope(state: /State.securityStructureConfigs, action: /Action.securityStructureConfigs) {
				SecurityStructureConfigurationListCoordinator()
			}
		}
	}

	// MARK: Reducer

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dismiss) var dismiss

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

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

		case .securityStructureConfigsButtonTapped:
			state.destination = .securityStructureConfigs(.init())
			return .none

		case .debugUserDefaultsContentsButtonTapped:
			state.destination = .debugUserDefaultsContents(.init())
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
