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
		public let oneTimeAccountsWithoutProofOfOwnership: OneTimeAccountsWithoutProofOfOwnershipRequestResponseItem?
		public let oneTimeAccountsWithProofOfOwnership: OneTimeAccountsWithProofOfOwnershipRequestResponseItem?
		public let oneTimePersonaData: OneTimePersonaDataRequestResponseItem?

		public init(
			oneTimeAccountsWithoutProofOfOwnership: OneTimeAccountsWithoutProofOfOwnershipRequestResponseItem?,
			oneTimeAccountsWithProofOfOwnership: OneTimeAccountsWithProofOfOwnershipRequestResponseItem?,
			oneTimePersonaData: OneTimePersonaDataRequestResponseItem?
		) {
			self.oneTimeAccountsWithoutProofOfOwnership = oneTimeAccountsWithoutProofOfOwnership
			self.oneTimeAccountsWithProofOfOwnership = oneTimeAccountsWithProofOfOwnership
			self.oneTimePersonaData = oneTimePersonaData
		}
	}

	public struct AuthorizedRequestResponseItems: Sendable, Hashable, Encodable {
		public let discriminator = P2P.Dapp.Request.Items.Discriminator.authorizedRequest.rawValue
		public let auth: AuthRequestResponseItem
		public let ongoingAccountsWithoutProofOfOwnership: OngoingAccountsWithoutProofOfOwnershipRequestResponseItem?
		public let ongoingAccountsWithProofOfOwnership: OngoingAccountsWithProofOfOwnershipRequestResponseItem?
		public let ongoingPersonaData: OngoingPersonaDataRequestResponseItem?
		public let oneTimeAccountsWithoutProofOfOwnership: OneTimeAccountsWithoutProofOfOwnershipRequestResponseItem?
		public let oneTimeAccountsWithProofOfOwnership: OneTimeAccountsWithProofOfOwnershipRequestResponseItem?
		public let oneTimePersonaData: OneTimePersonaDataRequestResponseItem?

		public init(
			auth: AuthRequestResponseItem,
			ongoingAccountsWithoutProofOfOwnership: OngoingAccountsWithoutProofOfOwnershipRequestResponseItem?,
			ongoingAccountsWithProofOfOwnership: OngoingAccountsWithProofOfOwnershipRequestResponseItem?,
			ongoingPersonaData: OngoingPersonaDataRequestResponseItem?,
			oneTimeAccountsWithoutProofOfOwnership: OneTimeAccountsWithoutProofOfOwnershipRequestResponseItem?,
			oneTimeAccountsWithProofOfOwnership: OneTimeAccountsWithProofOfOwnershipRequestResponseItem?,
			oneTimePersonaData: OneTimePersonaDataRequestResponseItem?
		) {
			self.auth = auth
			self.ongoingAccountsWithoutProofOfOwnership = ongoingAccountsWithoutProofOfOwnership
			self.ongoingAccountsWithProofOfOwnership = ongoingAccountsWithProofOfOwnership
			self.ongoingPersonaData = ongoingPersonaData
			self.oneTimeAccountsWithoutProofOfOwnership = oneTimeAccountsWithoutProofOfOwnership
			self.oneTimeAccountsWithProofOfOwnership = oneTimeAccountsWithProofOfOwnership
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
