import ComposableArchitecture
import SwiftUI

struct DebugSettingsCoordinator: FeatureReducer {
	typealias Store = StoreOf<Self>

	// MARK: State

	struct State: Hashable {
		@PresentationState
		var destination: Destination.State?

		init() {}
	}

	// MARK: Action

	enum ViewAction: Equatable {
		case factorSourcesButtonTapped
		case debugInspectProfileButtonTapped
		case debugUserDefaultsContentsButtonTapped
		case debugTestKeychainButtonTapped
		case debugKeychainContentsButtonTapped
		case debugFactorInstancesCacheContentsButtonTapped
	}

	enum InternalAction: Equatable {
		case profileToDebugLoaded(Profile)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Hashable {
			case debugUserDefaultsContents(DebugUserDefaultsContents.State)
			case debugInspectProfile(DebugInspectProfile.State)
			case debugManageFactorSources(DebugManageFactorSources.State)
			#if DEBUG
			case debugKeychainTest(DebugKeychainTest.State)
			case debugKeychainContents(DebugKeychainContents.State)
			case debugFactorInstancesCacheContents(DebugFactorInstancesCacheContents.State)
			#endif // DEBUG
		}

		@CasePathable
		enum Action: Equatable {
			case debugUserDefaultsContents(DebugUserDefaultsContents.Action)
			case debugInspectProfile(DebugInspectProfile.Action)
			#if DEBUG
			case debugKeychainTest(DebugKeychainTest.Action)
			case debugKeychainContents(DebugKeychainContents.Action)
			case debugFactorInstancesCacheContents(DebugFactorInstancesCacheContents.Action)
			#endif // DEBUG
			case debugManageFactorSources(DebugManageFactorSources.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(
				state: \.debugUserDefaultsContents,
				action: \.debugUserDefaultsContents
			) {
				DebugUserDefaultsContents()
			}
			Scope(
				state: \.debugInspectProfile,
				action: \.debugInspectProfile
			) {
				DebugInspectProfile()
			}
			#if DEBUG
			Scope(state: /State.debugKeychainTest, action: /Action.debugKeychainTest) {
				DebugKeychainTest()
			}
			Scope(state: /State.debugKeychainContents, action: /Action.debugKeychainContents) {
				DebugKeychainContents()
			}
			Scope(state: /State.debugFactorInstancesCacheContents, action: /Action.debugFactorInstancesCacheContents) {
				DebugFactorInstancesCacheContents()
			}
			#endif // DEBUG
			Scope(state: /State.debugManageFactorSources, action: /Action.debugManageFactorSources) {
				DebugManageFactorSources()
			}
		}
	}

	// MARK: Reducer

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dismiss) var dismiss

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .factorSourcesButtonTapped:
			state.destination = .debugManageFactorSources(.init())
			return .none

		case .debugInspectProfileButtonTapped:
			return .run { send in
				let profile = await appPreferencesClient.extractProfile()
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

		case .debugFactorInstancesCacheContentsButtonTapped:
			#if DEBUG
			state.destination = .debugFactorInstancesCacheContents(.init())
			#endif // DEBUG
			return .none

		case .debugUserDefaultsContentsButtonTapped:
			state.destination = .debugUserDefaultsContents(.init())
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .profileToDebugLoaded(profile):
			state.destination = .debugInspectProfile(.init(profile: profile))
			return .none
		}
	}
}
