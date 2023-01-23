import Cryptography
import FeaturePrelude

// MARK: - GatherFactor
public struct GatherFactor: Sendable, ReducerProtocol {
	public init() {}
}

public extension GatherFactor {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.mockResultButtonTapped)):

			return .run { [id = state.id] send in
				let privateKey = CryptoKit.Curve25519.Signing.PrivateKey()
				let publicKey = privateKey.publicKey
				let mockedResult = GatherFactorResult.publicKey(.eddsaEd25519(publicKey))

				await send(.delegate(.finishedWithResult(id: id, mockedResult)))
			}
		default: return .none
		}
	}
}
