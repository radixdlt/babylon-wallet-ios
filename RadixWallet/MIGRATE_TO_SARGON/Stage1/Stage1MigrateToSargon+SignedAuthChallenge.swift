import Foundation
import Sargon

// MARK: - SignedAuthChallenge
public struct SignedAuthChallenge: Sendable, Hashable {
	public let challenge: DappToWalletInteractionAuthChallengeNonce
	public let entitySignatures: Set<SignatureOfEntity>
	public init(challenge: DappToWalletInteractionAuthChallengeNonce, entitySignatures: Set<SignatureOfEntity>) {
		self.challenge = challenge
		self.entitySignatures = entitySignatures
	}
}
