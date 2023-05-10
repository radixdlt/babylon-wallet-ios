import Prelude
import Profile

// MARK: - P2P.Dapp
extension P2P {
	/// Just a namespace
	public enum Dapp {}
}

// MARK: - SignedAuthChallenge
public struct SignedAuthChallenge: Sendable, Hashable {
	public let challenge: P2P.Dapp.Request.AuthChallengeNonce
	public let entitySignatures: Set<SignatureOfEntity>
	public init(challenge: P2P.Dapp.Request.AuthChallengeNonce, entitySignatures: Set<SignatureOfEntity>) {
		self.challenge = challenge
		self.entitySignatures = entitySignatures
	}
}

// MARK: - P2P.Dapp.Request.AuthChallengeNonce
extension P2P.Dapp.Request {
	/// A 32 bytes nonce used as a challenge
	public typealias AuthChallengeNonce = Tagged<(Self, nonce: ()), HexCodable32Bytes>
}

// MARK: - P2P.Dapp.Response
extension P2P.Dapp {
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

extension P2P.Dapp.Response {
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

	public struct ChallengeWithProof: Sendable, Hashable {
		public let challenge: P2P.Dapp.Request.AuthChallengeNonce
		public let proof: P2P.Dapp.Response.AuthProof
		public init(challenge: P2P.Dapp.Request.AuthChallengeNonce, proof: P2P.Dapp.Response.AuthProof) {
			self.challenge = challenge
			self.proof = proof
		}
	}

	public enum Accounts: Sendable, Hashable {
		case withoutProofOfOwnership(IdentifiedArrayOf<Profile.Network.Account>)
		case withProofOfOwnership(challenge: P2P.Dapp.Request.AuthChallengeNonce, IdentifiedArrayOf<WithProof>)

		public struct WithProof: Sendable, Hashable, Encodable, Identifiable {
			public typealias ID = WalletAccount
			public var id: ID { account }
			public let account: WalletAccount

			public let proof: P2P.Dapp.Response.AuthProof

			public init(
				account: WalletAccount,
				proof: P2P.Dapp.Response.AuthProof
			) {
				self.account = account
				self.proof = proof
			}
		}
	}
}
