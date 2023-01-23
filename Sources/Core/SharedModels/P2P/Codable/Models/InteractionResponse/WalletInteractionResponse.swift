import Prelude

// MARK: - P2P.ToDapp
public extension P2P {
	/// Just a namespace
	enum ToDapp {}
}

// MARK: - P2P.ToDapp.WalletInteractionResponse
public extension P2P.ToDapp {
	enum WalletInteractionResponse: Sendable, Hashable, Encodable {
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
