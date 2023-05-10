import Prelude
import Profile

extension P2P.Dapp.Request {
	public struct LoginRequestItem: Sendable, Hashable, Decodable {
		public let challenge: P2P.Dapp.Request.AuthChallengeNonce?
		public let identityAddress: IdentityAddress?

		public init(
			challenge: P2P.Dapp.Request.AuthChallengeNonce?,
			identityAddress: IdentityAddress?
		) {
			self.challenge = challenge
			self.identityAddress = identityAddress
		}
	}
}
