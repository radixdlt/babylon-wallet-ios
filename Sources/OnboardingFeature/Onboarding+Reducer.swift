import ComposableArchitecture
import Profile
import Wallet

public extension Onboarding {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { state, action, environment in
		switch action {
		case .coordinate:
			return .none
		case .internal(.user(.createWallet)):
			return Effect(value: .internal(.system(.createWallet)))
		case .internal(.system(.createWallet)):
			precondition(state.canProceed)
			let profile = try! Profile(name: state.profileName)
			// FIXME: insert right mnemonic
			let wallet: Wallet = .init(profile: profile, deviceFactorTypeMnemonic: "")
			let name = state.profileName
			return .run { send in
				await environment.userDefaultsClient.setProfileName(name)
				await send(.internal(.system(.createdWallet(wallet))))
			}

		case let .internal(.system(.createdWallet(wallet))):
			return Effect(value: .coordinate(.onboardedWithWallet(wallet)))
		case .binding:
			state.canProceed = !state.profileName.isEmpty
			return .none
		}
	}
	.binding()
}
