import FeaturePrelude

// MARK: - P2P.FromDapp.WalletRequestItem
public extension P2P.FromDapp.WalletInteraction {
	/// A union type containing all request items allowed in a `WalletInteraction`, for app handling purposes.
	enum AnyInteractionItem: Sendable, Hashable {
		// requests
		case auth(AuthRequestItem)
		case oneTimeAccounts(OneTimeAccountsRequestItem)
		case ongoingAccounts(OngoingAccountsRequestItem)

		// transactions
		case send(SendTransactionItem)
	}

	// NB: keep this logic synced up with the enum above
	// Future reflection metadata capabilities should make this
	// implementation simpler and with no need to keep it manually synced up.
	var erasedItems: [AnyInteractionItem] {
		switch items {
		case let .request(.authorized(items)):
			return [
				.auth(items.auth),
				items.oneTimeAccounts.map(AnyInteractionItem.oneTimeAccounts),
				items.ongoingAccounts.map(AnyInteractionItem.ongoingAccounts),
			]
			.compactMap { $0 }
		case let .request(.unauthorized(items)):
			return [
				items.oneTimeAccounts.map(AnyInteractionItem.oneTimeAccounts),
			]
			.compactMap { $0 }
		case let .transaction(items):
			return [
				.send(items.send),
			]
			.compactMap { $0 }
		}
	}
}

// MARK: - P2P.ToDapp.WalletInteractionSuccessResponse.AnyInteractionResponseItem
public extension P2P.ToDapp.WalletInteractionSuccessResponse {
	enum AnyInteractionResponseItem: Sendable, Hashable {
		// request responses
		case auth(AuthRequestResponseItem)
		case oneTimeAccounts(OneTimeAccountsRequestResponseItem)
		case ongoingAccounts(OngoingAccountsRequestResponseItem)

		// transaction responses
		case send(SendTransactionResponseItem)
	}
}
