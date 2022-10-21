import ComposableArchitecture
import Mnemonic
import Profile
import ProfileClient

public extension Onboarding {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { state, action, environment in
		switch action {
		case .coordinate:
			return .none
		case .internal(.user(.createProfile)):
			return .run { send in
				await send(.internal(.system(.createProfile)))
			}
		case .internal(.system(.createProfile)):
			precondition(state.canProceed)
			return .run { [nameOfFirstAccount = state.nameOfFirstAccount] send in
				let curve25519FactorSourceMnemonic = try environment.mnemonicGenerator(BIP39.WordCount.twentyFour, BIP39.Language.english)

				let newProfile = try await Profile.new(
					mnemonic: curve25519FactorSourceMnemonic,
					firstAccountDisplayName: nameOfFirstAccount
				)

				let curve25519FactorSourceReference = newProfile.factorSources.curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources.first.reference

				try environment.keychainClient.saveFactorSource(
					mnemonic: curve25519FactorSourceMnemonic,
					reference: curve25519FactorSourceReference
				)

				try environment.keychainClient.saveProfile(profile: newProfile)

				await send(.internal(.system(.createdProfile(newProfile))))
			}
		case let .internal(.system(.createdProfile(profile))):
			return .run { send in
				await send(.coordinate(.onboardedWithProfile(profile)))
			}
		case .binding:
			state.canProceed = !state.nameOfFirstAccount.isEmpty
			return .none
		}
	}
	.binding()
}
