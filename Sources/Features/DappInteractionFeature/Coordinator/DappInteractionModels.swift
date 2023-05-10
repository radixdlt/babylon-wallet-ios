import FeaturePrelude

// MARK: - DappInteraction
enum DappInteraction {}

// MARK: DappInteraction.NumberOfAccounts
extension DappInteraction {
	typealias NumberOfAccounts = P2P.Dapp.Request.NumberOfAccounts
}

// MARK: - DappMetadata
struct DappMetadata: Sendable, Hashable, Codable {
	static let defaultName = NonEmptyString(rawValue: L10n.DApp.Metadata.unknownName)!

	let name: NonEmpty<String>
	let description: String?
	let origin: P2P.Dapp.Request.Metadata.Origin

	init(
		name: String?,
		description: String? = nil,
		origin: P2P.Dapp.Request.Metadata.Origin
	) {
		self.name = name.flatMap(NonEmptyString.init(rawValue:)) ?? Self.defaultName
		self.description = description
		self.origin = origin
	}
}

#if DEBUG
extension DappMetadata {
	static let previewValue: Self = .init(
		name: "Collabo.Fi",
		description: "A very collaby finance dapp",
		origin: .init(rawValue: "https://radfi.com")
	)
}
#endif

// MARK: - P2P.Dapp.Request.WalletRequestItem
extension P2P.Dapp.Request {
	/// A union type containing all request items allowed in a `WalletInteraction`, for app handling purposes.
	enum AnyInteractionItem: Sendable, Hashable {
		// requests
		case login(LoginRequestItem)
		case oneTimeAccounts(AccountsRequestItem)
		case ongoingAccounts(AccountsRequestItem)
		case oneTimePersonaData(PersonaDataRequestItem)
		case ongoingPersonaData(PersonaDataRequestItem)

		// transactions
		case send(SendTransactionItem)

		var priority: some Comparable {
			switch self {
			// requests
			case .login:
				return 0
			case .ongoingAccounts:
				return 1
			case .ongoingPersonaData:
				return 2
			case .oneTimeAccounts:
				return 3
			case .oneTimePersonaData:
				return 4

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
				.login(items.login),
				items.oneTimeAccounts.map(AnyInteractionItem.oneTimeAccounts),
				items.ongoingAccounts.map(AnyInteractionItem.ongoingAccounts),
				items.oneTimePersonaData.map(AnyInteractionItem.oneTimePersonaData),
				items.ongoingPersonaData.map(AnyInteractionItem.ongoingPersonaData),
			]
			.compactMap { $0 }
		case let .request(.unauthorized(items)):
			return [
				items.oneTimeAccounts.map(AnyInteractionItem.oneTimeAccounts),
				items.oneTimePersonaData.map(AnyInteractionItem.oneTimePersonaData),
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

// MARK: - P2P.Dapp.Response.WalletInteractionSuccessResponse.AnyInteractionResponseItem
extension P2P.Dapp.Response.WalletInteractionSuccessResponse {
	enum AnyInteractionResponseItem: Sendable, Hashable {
		// request responses
		case login(LoginRequestResponseItem)
		case oneTimeAccounts(AccountsRequestResponseItem)
		case ongoingAccounts(AccountsRequestResponseItem)
		case oneTimePersonaData(PersonaDataRequestResponseItem)
		case ongoingPersonaData(PersonaDataRequestResponseItem)

		// transaction responses
		case send(SendTransactionResponseItem)
	}

	init?(
		for interaction: P2P.Dapp.Request,
		with items: some Collection<P2P.Dapp.Response.WalletInteractionSuccessResponse.AnyInteractionResponseItem>
	) {
		switch interaction.items {
		case .request:
			// NB: variadic generics + native case paths should greatly help to simplify this "picking" logic
			var login: LoginRequestResponseItem? = nil
			var oneTimeAccounts: AccountsRequestResponseItem? = nil
			var ongoingAccounts: AccountsRequestResponseItem? = nil
			var oneTimePersonaData: PersonaDataRequestResponseItem? = nil
			var ongoingPersonaData: PersonaDataRequestResponseItem? = nil

			for item in items {
				switch item {
				case let .login(item):
					login = item
				case let .ongoingAccounts(item):
					ongoingAccounts = item
				case let .ongoingPersonaData(item):
					ongoingPersonaData = item
				case let .oneTimeAccounts(item):
					oneTimeAccounts = item
				case let .oneTimePersonaData(item):
					oneTimePersonaData = item
				case .send:
					continue
				}
			}

			if let login {
				self.init(
					interactionId: interaction.id,
					items: .request(
						.authorized(.init(
							login: login,
							oneTimeAccounts: oneTimeAccounts,
							oneTimePersonaData: oneTimePersonaData,
							ongoingAccounts: ongoingAccounts,
							ongoingPersonaData: ongoingPersonaData
						))
					)
				)
			} else {
				self.init(
					interactionId: interaction.id,
					items: .request(
						.unauthorized(.init(
							oneTimeAccounts: oneTimeAccounts,
							oneTimePersonaData: oneTimePersonaData
						))
					)
				)
			}

		case .transaction:
			var send: SendTransactionResponseItem? = nil
			for item in items {
				switch item {
				case .login, .ongoingAccounts, .ongoingPersonaData, .oneTimeAccounts, .oneTimePersonaData:
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
