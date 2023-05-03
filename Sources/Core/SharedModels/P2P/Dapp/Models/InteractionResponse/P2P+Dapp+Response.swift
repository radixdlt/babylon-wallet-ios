import Prelude

// MARK: - P2P.Dapp
extension P2P {
	/// Just a namespace
	public enum Dapp {}
}

// MARK: - P2P.Dapp.Response
extension P2P.Dapp {
	/// A 32 bytes nonce used as a challenge
	public typealias AuthChallengeNonce = Tagged<(Self, nonce: ()), HexCodable32Bytes>
	public struct AuthProof: Sendable, Hashable, Codable {
		public let publicKey: String
		public let curve: String
		public let signature: String
		public init(publicKey: String, curve: String, signature: String) {
			self.publicKey = publicKey
			self.curve = curve
			self.signature = signature
		}
	}

	public enum Response: Sendable, Hashable, Encodable {
		private enum CodingKeys: String, CodingKey {
			case discriminator
		}

		private enum Discriminator: String, Encodable {
			case success
			case failure
		}

		case success(WalletInteractionSuccessResponse)
		case failure(WalletInteractionFailureResponse)

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			switch self {
			case let .success(success):
				try container.encode(Discriminator.success, forKey: .discriminator)
				try success.encode(to: encoder)
			case let .failure(failure):
				try container.encode(Discriminator.failure, forKey: .discriminator)
				try failure.encode(to: encoder)
			}
		}
	}
}
