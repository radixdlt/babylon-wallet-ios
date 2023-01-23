import Prelude

// MARK: - P2P.ToDapp.WalletInteractionSuccessResponse.Items
public extension P2P.ToDapp.WalletInteractionSuccessResponse {
	enum Items: Sendable, Hashable, Encodable {
		case request(RequestResponseItems)
		case transaction(TransactionResponseItems)

		public func encode(to encoder: Encoder) throws {
			switch self {
			case let .request(.unauthorized(items)):
				try items.encode(to: encoder)
			case let .request(.authorized(items)):
				try items.encode(to: encoder)
			case let .transaction(items):
				try items.encode(to: encoder)
			}
		}
	}
}

public extension P2P.ToDapp.WalletInteractionSuccessResponse {
	enum RequestResponseItems: Sendable, Hashable {
		case unauthorized(UnauthorizedRequestResponseItems)
		case authorized(AuthorizedRequestResponseItems)
	}

	struct UnauthorizedRequestResponseItems: Sendable, Hashable, Encodable {
		public let discriminator = P2P.FromDapp.WalletInteraction.Items.Discriminator.unauthorizedRequest.rawValue
		public let oneTimeAccounts: OneTimeAccountsResponseItem?
	}

	struct AuthorizedRequestResponseItems: Sendable, Hashable, Encodable {
		public let discriminator = P2P.FromDapp.WalletInteraction.Items.Discriminator.authorizedRequest.rawValue
//		public let auth: AuthResponseItem
		public let oneTimeAccounts: OneTimeAccountsResponseItem?
	}
}

// MARK: - P2P.ToDapp.WalletInteractionSuccessResponse.TransactionResponseItems
public extension P2P.ToDapp.WalletInteractionSuccessResponse {
	struct TransactionResponseItems: Sendable, Hashable, Encodable {
		public let discriminator = P2P.FromDapp.WalletInteraction.Items.Discriminator.transaction.rawValue
		public let send: SendTransactionResponseItem
	}
}
