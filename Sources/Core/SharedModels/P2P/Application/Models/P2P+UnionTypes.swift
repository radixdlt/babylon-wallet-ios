import Prelude

// MARK: - P2P.FromDapp.WalletRequestItem
public extension P2P.FromDapp.WalletInteraction {
	/// A union type containing all request items allowed in a `WalletInteraction`, for app handling purposes.
	enum AnyInteractionItem: Sendable, Hashable {
		// requests
		case auth(AuthRequestItem)
		case oneTimeAccounts(OneTimeAccountsRequestItem)

		// transactions
		case send(SendTransactionItem)
	}

	// NB: keep this logic synced up with the enum above
	var erasedItems: [P2P.FromDapp.WalletInteraction.AnyInteractionItem] {
		switch items {
		case let .request(.authorized(items)):
			return .build {
				.auth(items.auth)
				if let oneTimeAccounts = items.oneTimeAccounts {
					.oneTimeAccounts(oneTimeAccounts)
				}
			}
		case let .request(.unauthorized(items)):
			return .build {
				if let oneTimeAccounts = items.oneTimeAccounts {
					.oneTimeAccounts(oneTimeAccounts)
				}
			}
		case let .transaction(items):
			return .build {
				.send(items.send)
			}
		}
	}
}

// MARK: - P2P.ToDapp.WalletInteractionSuccessResponse.AnyInteractionResponseItem
public extension P2P.ToDapp.WalletInteractionSuccessResponse {
	enum AnyInteractionResponseItem: Sendable, Hashable {
		// request responses
		case auth(AuthRequestResponseItem)
		case oneTimeAccounts(OneTimeAccountsRequestResponseItem)

		// transaction responses
		case send(SendTransactionResponseItem)
	}
}

// internal extension P2P.FromDapp.WalletRequestItem {
//	var discriminator: P2P.FromDapp.Discriminator {
//		switch self {
//		case .sendTransaction: return .sendTransactionWrite
//		case .oneTimeAccounts: return .oneTimeAccountsRead
//		}
//	}
// }

//// MARK: As OneTimeAccountsReadRequestItem
// public extension P2P.FromDapp.WalletInteraction.AnyInteractionItem {
//	var oneTimeAccounts: P2P.FromDapp.WalletInteraction.OneTimeAccountsRequestItem? {
//		guard case let .oneTimeAccounts(item) = self else {
//			return nil
//		}
//		return item
//	}
//
////	struct ExpectedOneTimeAccountAddressesRequest: Swift.Error {}
////	func asOneTimeAccountAddresses() throws -> P2P.FromDapp.WalletInteraction.OneTimeAccountsRequestItem {
////		guard let oneTimeAccounts else {
////			throw ExpectedOneTimeAccountAddressesRequest()
////		}
////		return oneTimeAccounts
////	}
// }
//
//// MARK: As SendTransactionWriteRequestItem
// public extension P2P.FromDapp.WalletInteraction.AnyInteractionItem {
//	var sendTransaction: P2P.FromDapp.WalletInteraction.SendTransactionItem? {
//		guard case let .sendTransaction(item) = self else {
//			return nil
//		}
//		return item
//	}
//
////	struct ExpectedSignTransactionRequest: Swift.Error {}
////	func asSignTransaction() throws -> P2P.FromDapp.SendTransactionWriteRequestItem {
////		guard let sendTransaction else {
////			throw ExpectedSignTransactionRequest()
////		}
////		return sendTransaction
////	}
// }
