import EngineKit
import Prelude
import Profile

// MARK: - P2P.Dapp.Request.AuthRequestItem
extension P2P.Dapp.Request {
	public enum AuthRequestItem: Sendable, Hashable, Decodable {
		private enum CodingKeys: String, CodingKey {
			case discriminator
		}

		enum Discriminator: String, Decodable {
			case loginWithoutChallenge
			case loginWithChallenge
			case usePersona
		}

		case login(AuthLoginRequestItem)
		case usePersona(AuthUsePersonaRequestItem)

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			let discriminator = try container.decode(Discriminator.self, forKey: .discriminator)
			switch discriminator {
			case .loginWithoutChallenge:
				self = .login(.withoutChallenge)
			case .loginWithChallenge:
				self = try .login(.withChallenge(.init(from: decoder)))
			case .usePersona:
				self = try .usePersona(.init(from: decoder))
			}
		}
	}
}

// MARK: - P2P.Dapp.Request.AuthLoginRequestItem
extension P2P.Dapp.Request {
	public enum AuthLoginRequestItem: Sendable, Hashable {
		case withoutChallenge
		case withChallenge(AuthLoginWithChallengeRequestItem)
	}
}

// MARK: - P2P.Dapp.Request.AuthLoginWithChallengeRequestItem
extension P2P.Dapp.Request {
	public struct AuthLoginWithChallengeRequestItem: Sendable, Hashable, Decodable {
		/// A 32 bytes nonce used as a challenge
		public let challenge: P2P.Dapp.Request.AuthChallengeNonce

		public init(challenge: P2P.Dapp.Request.AuthChallengeNonce) {
			self.challenge = challenge
		}
	}
}

// MARK: - P2P.Dapp.Request.AuthUsePersonaRequestItem
extension P2P.Dapp.Request {
	public struct AuthUsePersonaRequestItem: Sendable, Hashable, Decodable {
		public let identityAddress: IdentityAddress

		public init(identityAddress: IdentityAddress) {
			self.identityAddress = identityAddress
		}
	}
}
