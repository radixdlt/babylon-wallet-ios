// MARK: - P2P.Dapp
extension P2P {
	/// Just a namespace
	public enum Dapp {}
}

// MARK: - SignedAuthChallenge
public struct SignedAuthChallenge: Sendable, Hashable {
	public let challenge: DappToWalletInteractionAuthChallengeNonce
	public let entitySignatures: Set<SignatureOfEntity>
	public init(challenge: DappToWalletInteractionAuthChallengeNonce, entitySignatures: Set<SignatureOfEntity>) {
		self.challenge = challenge
		self.entitySignatures = entitySignatures
	}
}

// MARK: - P2P.Dapp.Response
// extension P2P.Dapp {
//	public enum Response: Sendable, Hashable, Encodable {
//		private enum CodingKeys: String, CodingKey {
//			case discriminator
//		}
//
//		private enum Discriminator: String, Encodable {
//			case success
//			case failure
//		}
//
//		case success(WalletInteractionSuccessResponse)
//		case failure(WalletInteractionFailureResponse)
//
//		public var id: P2P.Dapp.Request.ID {
//			switch self {
//			case let .success(response):
//				response.interactionId
//			case let .failure(response):
//				response.interactionId
//			}
//		}
//
//		public func encode(to encoder: Encoder) throws {
//			var container = encoder.container(keyedBy: CodingKeys.self)
//			switch self {
//			case let .success(success):
//				try container.encode(Discriminator.success, forKey: .discriminator)
//				try success.encode(to: encoder)
//			case let .failure(failure):
//				try container.encode(Discriminator.failure, forKey: .discriminator)
//				try failure.encode(to: encoder)
//			}
//		}
//	}
// }
