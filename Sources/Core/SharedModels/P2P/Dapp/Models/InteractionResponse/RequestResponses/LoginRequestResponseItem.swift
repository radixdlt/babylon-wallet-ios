import Prelude

extension P2P.Dapp.Response.WalletInteractionSuccessResponse {
	public struct LoginRequestResponseItem: Sendable, Hashable, Encodable {
		public let persona: P2P.Dapp.Response.Persona
		public let challenge: P2P.Dapp.Request.AuthChallengeNonce?
		public let proof: P2P.Dapp.Response.AuthProof?

		public init(
			persona: P2P.Dapp.Response.Persona,
			challengeWithProof: P2P.Dapp.Response.ChallengeWithProof?
		) throws {
			self.persona = persona
			self.challenge = challengeWithProof?.challenge
			self.proof = challengeWithProof?.proof
		}
	}
}
