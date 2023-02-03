import FeaturePrelude

// MARK: - P2P.FromDapp.WalletRequestItem
extension P2P.FromDapp.WalletInteraction {
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
extension P2P.ToDapp.WalletInteractionSuccessResponse {
	enum AnyInteractionResponseItem: Sendable, Hashable {
		// request responses
		case auth(AuthRequestResponseItem)
		case oneTimeAccounts(OneTimeAccountsRequestResponseItem)
		case ongoingAccounts(OngoingAccountsRequestResponseItem)

		// transaction responses
		case send(SendTransactionResponseItem)
	}

	init?(
		for interaction: P2P.FromDapp.WalletInteraction,
		with items: [P2P.ToDapp.WalletInteractionSuccessResponse.AnyInteractionResponseItem]
	) {
		switch interaction.items {
		case .request:
			// NB: variadic generics + native case paths should greatly help to simplify this "picking" logic
			var auth: AuthRequestResponseItem? = nil
			var oneTimeAccounts: OneTimeAccountsRequestResponseItem? = nil
			var ongoingAccounts: OngoingAccountsRequestResponseItem? = nil
			for item in items {
				switch item {
				case let .auth(item):
					auth = item
				case let .oneTimeAccounts(item):
					oneTimeAccounts = item
				case let .ongoingAccounts(item):
					ongoingAccounts = item
				case .send:
					continue
				}
			}

			if let auth {
				self.init(
					interactionId: interaction.id,
					items: .request(
						.authorized(.init(
							auth: auth,
							oneTimeAccounts: oneTimeAccounts,
							ongoingAccounts: ongoingAccounts
						))
					)
				)
			} else {
				self.init(
					interactionId: interaction.id,
					items: .request(
						.unauthorized(.init(
							oneTimeAccounts: oneTimeAccounts
						))
					)
				)
			}

		case .transaction:
			var send: SendTransactionResponseItem? = nil
			for item in items {
				switch item {
				case .auth:
					continue
				case .oneTimeAccounts:
					continue
				case .ongoingAccounts:
					continue
				case let .send(item):
					send = item
				}
			}

			// NB: remove this check and the init's optionality when `send` becomes optional (when we introduce more transaction item fields)
			guard let send else {
				return nil
			}

			self.init(
				interactionId: interaction.id,
				items: .transaction(.init(send: send))
			)
		}
	}
}
