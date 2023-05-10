import Prelude

// MARK: - P2P.Dapp.Request.Items
extension P2P.Dapp.Request {
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
				self = try .request(.unauthorized(.init(from: decoder)))
			case .authorizedRequest:
				self = try .request(.authorized(.init(from: decoder)))
			case .transaction:
				self = try .transaction(.init(from: decoder))
			}
		}
	}
}

extension P2P.Dapp.Request {
	public enum RequestItems: Sendable, Hashable {
		case unauthorized(UnauthorizedRequestItems)
		case authorized(AuthorizedRequestItems)
	}

	public struct UnauthorizedRequestItems: Sendable, Hashable, Decodable {
		public let oneTimeAccounts: AccountsRequestItem?
		public let oneTimePersonaData: PersonaDataRequestItem?

		public init(
			oneTimeAccounts: AccountsRequestItem?,
			oneTimePersonaData: PersonaDataRequestItem?
		) {
			self.oneTimeAccounts = oneTimeAccounts
			self.oneTimePersonaData = oneTimePersonaData
		}
	}

	public struct AuthorizedRequestItems: Sendable, Hashable, Decodable {
		public let login: LoginRequestItem
		public let reset: ResetRequestItem?
		public let accounts: AccountsRequestItem?
		public let personaData: PersonaDataRequestItem?

		public init(
			login: LoginRequestItem,
			reset: ResetRequestItem?,
			accounts: AccountsRequestItem?,
			personaData: PersonaDataRequestItem?
		) {
			self.login = login
			self.reset = reset
			self.accounts = accounts
			self.personaData = personaData
		}
	}
}

// MARK: - P2P.Dapp.Request.TransactionItems
extension P2P.Dapp.Request {
	public struct TransactionItems: Sendable, Hashable, Decodable {
		public let send: SendTransactionItem
	}
}
