import Prelude

// MARK: - P2P.FromDapp.WalletInteraction.Items
public extension P2P.FromDapp.WalletInteraction {
	enum Items: Sendable, Hashable, Decodable {
		private enum CodingKeys: String, CodingKey {
			case discriminator
		}

		enum Discriminator: String, Decodable {
			case unauthorizedRequest
			case authorizedRequest
			case transaction
		}

		case request(RequestItems)
		case transaction(TransactionItems)

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			let discriminator = try container.decode(Discriminator.self, forKey: .discriminator)
			switch discriminator {
			case .unauthorizedRequest:
				self = .request(.unauthorized(try .init(from: decoder)))
			case .authorizedRequest:
				self = .request(.authorized(try .init(from: decoder)))
			case .transaction:
				self = .transaction(try .init(from: decoder))
			}
		}
	}
}

public extension P2P.FromDapp.WalletInteraction {
	enum RequestItems: Sendable, Hashable {
		case unauthorized(UnauthorizedRequestItems)
		case authorized(AuthorizedRequestItems)
	}

	struct UnauthorizedRequestItems: Sendable, Hashable, Decodable {
		public let oneTimeAccounts: OneTimeAccountsRequestItem?
	}

	struct AuthorizedRequestItems: Sendable, Hashable, Decodable {
		public let auth: AuthRequestItem
		public let oneTimeAccounts: OneTimeAccountsRequestItem?
	}
}

// MARK: - P2P.FromDapp.WalletInteraction.TransactionItems
public extension P2P.FromDapp.WalletInteraction {
	struct TransactionItems: Sendable, Hashable, Decodable {
		public let send: SendTransactionItem
	}
}
