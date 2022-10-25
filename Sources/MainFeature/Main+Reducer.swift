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
		Home.reducer
			.pullback(
				state: \.home,
				action: /Main.Action.home,
				environment: {
					Home.Environment(
						profileClient: $0.profileClient,
						appSettingsClient: $0.appSettingsClient,
						accountPortfolioFetcher: $0.accountPortfolioFetcher,
						pasteboardClient: $0.pasteboardClient
					)
				}
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

			case .settings(.coordinate(.deleteProfileAndFactorSources)):
				return .run { send in
					try environment.keychainClient.removeAllFactorSourcesAndProfileSnapshot()
					try environment.profileClient.deleteProfileSnapshot()
					await send(.coordinate(.removedWallet))
				}

			case .settings(.coordinate(.dismissSettings)):
				state.settings = nil
				return .none

			case .settings(.internal(_)):
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

			#if DEBUG
			case .home(.connectionRequest(_)):
				return .none
			#endif
			}
		}
	)
	// .debug()
}
