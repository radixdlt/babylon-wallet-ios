import FeaturePrelude

// MARK: - DappInteraction
enum DappInteraction {}

// MARK: DappInteraction.NumberOfAccounts
extension DappInteraction {
	typealias NumberOfAccounts = P2P.FromDapp.WalletInteraction.NumberOfAccounts
}

// MARK: - DappMetadata
struct DappMetadata: Sendable, Hashable {
	static let defaultName = NonEmptyString(rawValue: L10n.DApp.Metadata.unknownName)!

	let name: NonEmpty<String>
	let description: String?

	init(
		name: String?,
		description: String? = nil
	) {
		self.name = name.flatMap(NonEmptyString.init(rawValue:)) ?? Self.defaultName
		self.description = description
	}
}

#if DEBUG
extension DappMetadata {
	static let previewValue: Self = .init(
		name: "Collabo.Fi",
		description: "A very collaby finance dapp"
	)
}
#endif

// MARK: - P2P.FromDapp.WalletRequestItem
extension P2P.FromDapp.WalletInteraction {
	/// A union type containing all request items allowed in a `WalletInteraction`, for app handling purposes.
	enum AnyInteractionItem: Sendable, Hashable {
		// requests
		case auth(AuthRequestItem)
		case ongoingAccounts(OngoingAccountsRequestItem)
		case ongoingPersonaData(OngoingPersonaDataRequestItem)
		case oneTimeAccounts(OneTimeAccountsRequestItem)

		// transactions
		case send(SendTransactionItem)

		var priority: some Comparable {
			switch self {
			// requests
			case .auth:
				return 0
			case .ongoingAccounts:
				return 1
			case .ongoingPersonaData:
				return 2
			case .oneTimeAccounts:
				return 3

			// transactions
			case .send:
				return 0
			}
		}
	}

	// NB: keep this logic synced up with the enum above
	// Future reflection metadata capabilities should make this
	// implementation simpler and with no need to keep it manually synced up.
	var erasedItems: [AnyInteractionItem] {
		switch items {
		case let .request(.authorized(items)):
			return [
				.auth(items.auth),
				items.ongoingAccounts.map(AnyInteractionItem.ongoingAccounts),
				items.ongoingPersonaData.map(AnyInteractionItem.ongoingPersonaData),
				items.oneTimeAccounts.map(AnyInteractionItem.oneTimeAccounts),
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
		case ongoingAccounts(OngoingAccountsRequestResponseItem)
		case ongoingPersonaData(OngoingPersonaDataRequestResponseItem)
		case oneTimeAccounts(OneTimeAccountsRequestResponseItem)

		// transaction responses
		case send(SendTransactionResponseItem)
	}

	init?(
		for interaction: P2P.FromDapp.WalletInteraction,
		with items: some Collection<P2P.ToDapp.WalletInteractionSuccessResponse.AnyInteractionResponseItem>
	) {
		switch interaction.items {
		case .request:
			// NB: variadic generics + native case paths should greatly help to simplify this "picking" logic
			var auth: AuthRequestResponseItem? = nil
			var ongoingAccounts: OngoingAccountsRequestResponseItem? = nil
			var ongoingPersonaData: OngoingPersonaDataRequestResponseItem? = nil
			var oneTimeAccounts: OneTimeAccountsRequestResponseItem? = nil
			for item in items {
				switch item {
				case let .auth(item):
					auth = item
				case let .ongoingAccounts(item):
					ongoingAccounts = item
				case let .ongoingPersonaData(item):
					ongoingPersonaData = item
				case let .oneTimeAccounts(item):
					oneTimeAccounts = item
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
							ongoingAccounts: ongoingAccounts,
							ongoingPersonaData: ongoingPersonaData,
							oneTimeAccounts: oneTimeAccounts
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
				case .ongoingAccounts:
					continue
				case .ongoingPersonaData:
					continue
				case .oneTimeAccounts:
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
