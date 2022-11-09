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
			action: /Main.Action.home,
			environment: { $0 }
		),

		// TODO: remove AnyReducer when migration to ReducerProtocol is complete
		AnyReducer { _ in
			Settings()
		}
		.optional()
		.pullback(
			state: \.settings,
			action: /Main.Action.settings,
			environment: { $0 }
		),

		Reducer { state, action, environment in
			switch action {
			case .home(.coordinate(.displaySettings)):
				state.settings = .init()
				return .none

			case .settings(.delegate(.deleteProfileAndFactorSources)):
				return .run { send in
					try environment.keychainClient.removeAllFactorSourcesAndProfileSnapshot()
					try await environment.profileClient.deleteProfileSnapshot()
					await send(.coordinate(.removedWallet))
				}

			case .settings(.delegate(.dismissSettings)):
				state.settings = nil
				return .none

			case .settings(.internal(_)):
				return .none

			case .settings(.manageBrowserExtensionConnections(_)):
				return .none

			case .home(.internal(_)):
				return .none
			case .home(.header(_)):
				return .none
			case .home(.accountList(_)):
				return .none
			case .home(.aggregatedValue(_)):
				return .none
			case .home(.visitHub(_)):
				return .none
			case .coordinate:
				return .none
			case .home(.accountPreferences(_)):
				return .none
			case .home(.accountDetails(_)):
				return .none
			case .home(.transfer(_)):
				return .none
			case .home(.createAccount(_)):
				return .none

			case .home(.chooseAccountRequestFromDapp(_)):
				return .none
			case .home(.transactionSigning(_)):
				return .none
			}
		}
	)
	// .debug()
}
