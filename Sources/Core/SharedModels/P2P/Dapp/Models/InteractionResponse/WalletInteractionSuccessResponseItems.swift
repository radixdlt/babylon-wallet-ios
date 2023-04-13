import Prelude

// MARK: - P2P.Dapp.Response.WalletInteractionSuccessResponse.Items
extension P2P.Dapp.Response.WalletInteractionSuccessResponse {
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

extension P2P.Dapp.Response.WalletInteractionSuccessResponse {
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
		public let discriminator = P2P.Dapp.Request.Items.Discriminator.unauthorizedRequest.rawValue
		public let oneTimeAccounts: OneTimeAccountsRequestResponseItem?
		public let oneTimePersonaData: OneTimePersonaDataRequestResponseItem?

		public init(
			oneTimeAccounts: OneTimeAccountsRequestResponseItem?,
			oneTimePersonaData: OneTimePersonaDataRequestResponseItem?
		) {
			self.oneTimeAccounts = oneTimeAccounts
			self.oneTimePersonaData = oneTimePersonaData
		}
	}

	public struct AuthorizedRequestResponseItems: Sendable, Hashable, Encodable {
		public let discriminator = P2P.Dapp.Request.Items.Discriminator.authorizedRequest.rawValue
		public let auth: AuthRequestResponseItem
		public let ongoingAccounts: OngoingAccountsRequestResponseItem?
		public let ongoingPersonaData: OngoingPersonaDataRequestResponseItem?
		public let oneTimeAccounts: OneTimeAccountsRequestResponseItem?
		public let oneTimePersonaData: OneTimePersonaDataRequestResponseItem?

		public init(
			auth: AuthRequestResponseItem,
			ongoingAccounts: OngoingAccountsRequestResponseItem?,
			ongoingPersonaData: OngoingPersonaDataRequestResponseItem?,
			oneTimeAccounts: OneTimeAccountsRequestResponseItem?,
			oneTimePersonaData: OneTimePersonaDataRequestResponseItem?
		) {
			self.auth = auth
			self.ongoingAccounts = ongoingAccounts
			self.ongoingPersonaData = ongoingPersonaData
			self.oneTimeAccounts = oneTimeAccounts
			self.oneTimePersonaData = oneTimePersonaData
		}
	}
}

// MARK: - P2P.Dapp.Response.WalletInteractionSuccessResponse.TransactionResponseItems
extension P2P.Dapp.Response.WalletInteractionSuccessResponse {
	public struct TransactionResponseItems: Sendable, Hashable, Encodable {
		public let discriminator = P2P.Dapp.Request.Items.Discriminator.transaction.rawValue
		public let send: SendTransactionResponseItem

		public init(send: P2P.Dapp.Response.WalletInteractionSuccessResponse.SendTransactionResponseItem) {
			self.send = send
		}
	}
}
