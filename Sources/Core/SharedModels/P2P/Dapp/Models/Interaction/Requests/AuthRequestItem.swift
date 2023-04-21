import Prelude

// MARK: - P2P.Dapp.Request.AuthRequestItem
extension P2P.Dapp.Request {
	public enum AuthRequestItem: Sendable, Hashable, Decodable {
		private enum CodingKeys: String, CodingKey {
			case discriminator
		}

		enum Discriminator: String, Decodable {
			case login
			case usePersona
		}

		case login(AuthLoginRequestItem)
		case usePersona(AuthUsePersonaRequestItem)

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			let discriminator = try container.decode(Discriminator.self, forKey: .discriminator)
			switch discriminator {
			case .login:
				self = try .login(.init(from: decoder))
			case .usePersona:
				self = try .usePersona(.init(from: decoder))
			}
		}
	}
}

// MARK: - P2P.Dapp.Request.AuthLoginRequestItem
extension P2P.Dapp.Request {
	public struct AuthLoginRequestItem: Sendable, Hashable, Decodable {
		public let challenge: String?

		public init(challenge: String?) {
			self.challenge = challenge
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
