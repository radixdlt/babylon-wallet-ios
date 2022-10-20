import ComposableArchitecture
import Profile
import WalletClient

public extension Settings {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { state, action, environment in
		switch action {
		case .internal(.user(.dismissSettings)):
			return .run { send in
				await send(.coordinate(.dismissSettings))
			}
		case .internal(.user(.deleteProfileAndFactorSources)):
			return .run { send in
				await send(.coordinate(.deleteProfileAndFactorSources))
			}

		#if DEBUG
		case .internal(.user(.debugInspectProfile)):

			return .run { send in
				guard
					let snapshot = try? environment.walletClient.extractProfileSnapshot(),
					let profile = try? Profile(snapshot: snapshot)
				else {
					return
				}
				await send(.internal(.system(.profileToDebugLoaded(profile))))
			}
		case let .internal(.system(.profileToDebugLoaded(profile))):
			state.profileToInspect = profile
			return .none
		case let .internal(.user(.setDebugProfileSheet(isPresented))):
			precondition(!isPresented)
			state.profileToInspect = nil
			return .none
		#endif // DEBUG

		case .coordinate:
			return .none
		}
	}
}
