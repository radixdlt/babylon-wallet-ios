import Cryptography
import FeaturePrelude
import Foundation
import Profile

// MARK: - SigningRequirements
public enum SigningRequirements: Sendable, Hashable {
	case signatoryAsNotary(
		singleFactor: FactorSource,
		account: Profile.Network.Account
	)

	case signers(
		factorsOfAccounts: FactorsOfAccounts,
		ephemeralNotary: Curve25519.Signing.PrivateKey
	)

	public struct FactorsOfAccounts: Sendable, Hashable {
		public let factorsOfAccounts: NonEmpty<OrderedDictionary<Profile.Network.Account, FactorSources>>
	}
}

// MARK: - Signing
public struct Signing: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let manifest: TransactionManifest
		public let signingRequirements: SigningRequirements
		public init(manifest: TransactionManifest) {
			self.manifest = manifest
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}
}
