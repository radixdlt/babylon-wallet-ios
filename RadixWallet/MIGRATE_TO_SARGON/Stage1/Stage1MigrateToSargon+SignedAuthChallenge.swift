import Foundation
import Sargon

// MARK: - SignedAuthChallenge
struct SignedAuthChallenge: Sendable, Hashable {
	let challenge: DappToWalletInteractionAuthChallengeNonce
	let entitySignatures: Set<SignatureOfEntity>
	init(challenge: DappToWalletInteractionAuthChallengeNonce, entitySignatures: Set<SignatureOfEntity>) {
		self.challenge = challenge
		self.entitySignatures = entitySignatures
	}
}
