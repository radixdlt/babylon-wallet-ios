import ComposableArchitecture
import HomeFeature
import Profile
import SettingsFeature

#if os(iOS)
// FIXME: move to `UIApplicationClient` package!
import UIKit
#endif

public extension Main {
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>

	// MARK: Reducer
	static let reducer = Reducer.combine(
		// TODO: remove AnyReducer when migration to ReducerProtocol is complete
		AnyReducer { _ in
			Home()
		}
		.pullback(
			state: \.home,
			action: /Main.Action.child .. Main.Action.ChildAction.home,
			environment: { $0 }
		),

		// TODO: remove AnyReducer when migration to ReducerProtocol is complete
		AnyReducer { _ in
			Settings()
		}
		.optional()
		.pullback(
			state: \.settings,
			action: /Main.Action.child .. Main.Action.ChildAction.settings,
			environment: { $0 }
		),

		Reducer { state, action, environment in
			switch action {
			case .child(.home(.delegate(.displaySettings))):
				state.settings = .init()
				return .none

			case .child(.settings(.delegate(.deleteProfileAndFactorSources))):
				return .run { send in
					try environment.keychainClient.removeAllFactorSourcesAndProfileSnapshot()
					try await environment.profileClient.deleteProfileSnapshot()
					await send(.delegate(.removedWallet))
				}

			case .child(.settings(.delegate(.dismissSettings))):
				state.settings = nil
				return .none

			case .child, .delegate:
				return .none
			}
		}
	)
	// .debug()
}
