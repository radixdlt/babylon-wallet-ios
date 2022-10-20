import ComposableArchitecture
import Profile
import WalletClient

public extension Onboarding {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { state, action, environment in
		switch action {
		case .coordinate:
			return .none
		case .internal(.user(.createProfile)):
			return Effect(value: .internal(.system(.createProfile)))
		case .internal(.system(.createProfile)):
			precondition(state.canProceed)
            
            // FIXME Wallet Client
            return .none
 
//
//            return .run { send in
//				await send(.internal(.system(.createdWallet(wallet))))
//			}

		case let .internal(.system(.createdProfile(profile))):
			return Effect(value: .coordinate(.onboardedWithProfile(profile)))
		case .binding:
			state.canProceed = !state.nameOfFirstAccount.isEmpty
			return .none
		}
	}
	.binding()
}
