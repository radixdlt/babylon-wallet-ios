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
		case accounts(AccountsRequestItem)
		case personaData(PersonaDataRequestItem)

		// transactions
		case send(SendTransactionItem)

		var priority: some Comparable {
			switch self {
			// requests
			case .login:
				return 0
			case let .accounts(request):
				if request.isOneTime {
					return 3
				} else {
					return 1
				}
			case let .personaData(request):
				if request.isOneTime {
					return 4
				} else {
					return 2
				}
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
				items.accounts.map(AnyInteractionItem.accounts),
				items.personaData.map(AnyInteractionItem.personaData),
			]
			.compactMap { $0 }
		case let .request(.unauthorized(items)):
			return [
				items.oneTimeAccounts.map(AnyInteractionItem.accounts),
				items.oneTimePersonaData.map(AnyInteractionItem.personaData),
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
		case accounts(AccountsRequestResponseItem)
		case personaData(PersonaDataRequestResponseItem)

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
			var accounts: AccountsRequestResponseItem? = nil
			var personaData: PersonaDataRequestResponseItem? = nil
			for item in items {
				switch item {
				case let .login(item):
					login = item
				case let .accounts(item):
					accounts = item
				case let .personaData(item):
					personaData = item
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
							accounts: accounts,
							personaData: personaData
						))
					)
				)
			} else {
				self.init(
					interactionId: interaction.id,
					items: .request(
						.unauthorized(.init(
							oneTimeAccounts: accounts,
							oneTimePersonaData: personaData
						))
					)
				)
			}

		case .transaction:
			var send: SendTransactionResponseItem? = nil
			for item in items {
				switch item {
				case .login, .personaData, .accounts:
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
