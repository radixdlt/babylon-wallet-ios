import Prelude

// MARK: - P2P.ToDapp.WalletInteractionSuccessResponse.Items
extension P2P.ToDapp.WalletInteractionSuccessResponse {
	public enum Items: Sendable, Hashable, Encodable {
		case request(RequestResponseItems)
		case transaction(TransactionResponseItems)

		public func encode(to encoder: Encoder) throws {
			switch self {
			case let .request(items):
				try items.encode(to: encoder)
			case let .transaction(items):
				try items.encode(to: encoder)
			}
		}
	}
}

extension P2P.ToDapp.WalletInteractionSuccessResponse {
	public enum RequestResponseItems: Sendable, Hashable, Encodable {
		case unauthorized(UnauthorizedRequestResponseItems)
		case authorized(AuthorizedRequestResponseItems)

		public func encode(to encoder: Encoder) throws {
			switch self {
			case let .unauthorized(items):
				try items.encode(to: encoder)
			case let .authorized(items):
				try items.encode(to: encoder)
			}
		}
	}

	public struct UnauthorizedRequestResponseItems: Sendable, Hashable, Encodable {
		public let discriminator = P2P.FromDapp.WalletInteraction.Items.Discriminator.unauthorizedRequest.rawValue
		public let oneTimeAccounts: OneTimeAccountsRequestResponseItem?

		public init(oneTimeAccounts: OneTimeAccountsRequestResponseItem?) {
			self.oneTimeAccounts = oneTimeAccounts
		}
	}

	public struct AuthorizedRequestResponseItems: Sendable, Hashable, Encodable {
		public let discriminator = P2P.FromDapp.WalletInteraction.Items.Discriminator.authorizedRequest.rawValue
		public let auth: AuthRequestResponseItem
		public let oneTimeAccounts: OneTimeAccountsRequestResponseItem?
		public let ongoingAccounts: OngoingAccountsRequestResponseItem?

		public init(
			auth: AuthRequestResponseItem,
			oneTimeAccounts: OneTimeAccountsRequestResponseItem?,
			ongoingAccounts: OngoingAccountsRequestResponseItem?
		) {
			self.auth = auth
			self.oneTimeAccounts = oneTimeAccounts
			self.ongoingAccounts = ongoingAccounts
		}
	}
}

// MARK: - P2P.ToDapp.WalletInteractionSuccessResponse.TransactionResponseItems
extension P2P.ToDapp.WalletInteractionSuccessResponse {
	public struct TransactionResponseItems: Sendable, Hashable, Encodable {
		public let discriminator = P2P.FromDapp.WalletInteraction.Items.Discriminator.transaction.rawValue
		public let send: SendTransactionResponseItem

		public init(send: P2P.ToDapp.WalletInteractionSuccessResponse.SendTransactionResponseItem) {
			self.send = send
		}
	}
}
