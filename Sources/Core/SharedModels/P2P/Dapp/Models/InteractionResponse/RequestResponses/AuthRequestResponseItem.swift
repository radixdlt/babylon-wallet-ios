import Prelude

// MARK: - P2P.Dapp.Response.WalletInteractionSuccessResponse.AuthRequestResponseItem
extension P2P.Dapp.Response.WalletInteractionSuccessResponse {
	public enum AuthRequestResponseItem: Sendable, Hashable, Encodable {
		case login(AuthLoginRequestResponseItem)
		case usePersona(AuthUsePersonaRequestResponseItem)

		public func encode(to encoder: Encoder) throws {
			switch self {
			case let .login(item):
				try item.encode(to: encoder)
			case let .usePersona(item):
				try item.encode(to: encoder)
			}
		}
	}
}

// MARK: - P2P.Dapp.Request.AuthLoginRequestItem
extension P2P.Dapp.Response.WalletInteractionSuccessResponse {
	public enum AuthLoginRequestResponseItem: Sendable, Hashable, Encodable {
		case withoutChallenge(AuthLoginWithoutChallengeRequestResponseItem)
		case withChallenge(AuthLoginWithChallengeRequestResponseItem)

		public func encode(to encoder: Encoder) throws {
			switch self {
			case let .withoutChallenge(item):
				try item.encode(to: encoder)
			case let .withChallenge(item):
				try item.encode(to: encoder)
			}
		}
	}

	public struct AuthLoginWithoutChallengeRequestResponseItem: Sendable, Hashable, Encodable {
		public let discriminator = "loginWithoutChallenge"
		public let persona: P2P.Dapp.Response.Persona

		public init(persona: P2P.Dapp.Response.Persona) {
			self.persona = persona
		}
	}

	public struct AuthLoginWithChallengeRequestResponseItem: Sendable, Hashable, Encodable {
		public let discriminator = "loginWithChallenge"
		public let persona: P2P.Dapp.Response.Persona
		public let challenge: P2P.Dapp.AuthChallengeNonce
		public let proof: P2P.Dapp.AuthProof

		public init(
			persona: P2P.Dapp.Response.Persona,
			challenge: P2P.Dapp.AuthChallengeNonce,
			proof: P2P.Dapp.AuthProof
		) {
			self.persona = persona
			self.challenge = challenge
			self.proof = proof
		}
	}
}

// MARK: - P2P.Dapp.Response.WalletInteractionSuccessResponse.AuthUsePersonaRequestResponseItem
extension P2P.Dapp.Response.WalletInteractionSuccessResponse {
	public struct AuthUsePersonaRequestResponseItem: Sendable, Hashable, Encodable {
		public let discriminator = P2P.Dapp.Request.AuthRequestItem.Discriminator.usePersona.rawValue
		public let persona: P2P.Dapp.Response.Persona

		public init(persona: P2P.Dapp.Response.Persona) {
			self.persona = persona
		}
	}
}
