import Prelude

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
				self = try .login(.init(from: decoder))
			case .loginWithChallenge:
				let auth = try AuthLoginRequestItem(from: decoder)
				guard auth.challenge != nil else {
					throw ExpectedAuthChallengeForLoginWithChallengeButGotNone()
				}
				self = .login(auth)
			case .usePersona:
				self = try .usePersona(.init(from: decoder))
			}
		}
	}
}

// MARK: - ExpectedAuthChallengeForLoginWithChallengeButGotNone
struct ExpectedAuthChallengeForLoginWithChallengeButGotNone: Swift.Error {}

// MARK: - P2P.Dapp.Request.AuthLoginRequestItem
extension P2P.Dapp.Request {
	public struct AuthLoginRequestItem: Sendable, Hashable, Decodable {
		/// A 32 bytes nonce used as a challenge
		public let challenge: P2P.Dapp.AuthChallengeNonce?

		public init(challenge: P2P.Dapp.AuthChallengeNonce?) {
			self.challenge = challenge
		}

		/// `challenge(32) || L_dda(1) || dda_utf8(L_dda) || origin_utf8`
		public static func payloadToHash(
			challenge: P2P.Dapp.AuthChallengeNonce,
			dAppDefinitionAddress: String,
			origin: String
		) -> Data {
			precondition(dAppDefinitionAddress.count <= 255)
			let challengeBytes = [UInt8](challenge.data.data)
			let lengthDappDefinitionAddress = UInt8(dAppDefinitionAddress.count)
			return Data(challengeBytes + [lengthDappDefinitionAddress] + [UInt8](dAppDefinitionAddress.utf8) + [UInt8](origin.utf8))
		}
	}
}

// MARK: - P2P.Dapp.Request.AuthUsePersonaRequestItem
extension P2P.Dapp.Request {
	public struct AuthUsePersonaRequestItem: Sendable, Hashable, Decodable {
		public let identityAddress: String

		public init(identityAddress: String) {
			self.identityAddress = identityAddress
		}
	}
}
