import Prelude

// MARK: - P2P.FromDapp.WalletInteraction.Items
extension P2P.FromDapp.WalletInteraction {
	public enum Items: Sendable, Hashable, Decodable {
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

extension P2P.FromDapp.WalletInteraction {
	public enum RequestItems: Sendable, Hashable {
		case unauthorized(UnauthorizedRequestItems)
		case authorized(AuthorizedRequestItems)
	}

	public struct UnauthorizedRequestItems: Sendable, Hashable, Decodable {
		public let oneTimeAccounts: OneTimeAccountsRequestItem?

		public init(oneTimeAccounts: OneTimeAccountsRequestItem?) {
			self.oneTimeAccounts = oneTimeAccounts
		}
	}

	public struct AuthorizedRequestItems: Sendable, Hashable, Decodable {
		public let auth: AuthRequestItem
		public let oneTimeAccounts: OneTimeAccountsRequestItem?
		public let ongoingAccounts: OngoingAccountsRequestItem?

		public init(
			auth: AuthRequestItem,
			oneTimeAccounts: OneTimeAccountsRequestItem?,
			ongoingAccounts: OngoingAccountsRequestItem?
		) {
			self.auth = auth
			self.oneTimeAccounts = oneTimeAccounts
			self.ongoingAccounts = ongoingAccounts
		}
	}
}

// MARK: - P2P.FromDapp.WalletInteraction.TransactionItems
extension P2P.FromDapp.WalletInteraction {
	public struct TransactionItems: Sendable, Hashable, Decodable {
		public let send: SendTransactionItem
	}
}
