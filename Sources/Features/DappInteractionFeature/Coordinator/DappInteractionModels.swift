import FeaturePrelude

// MARK: - DappInteraction
enum DappInteraction {}

// MARK: DappInteraction.NumberOfAccounts
extension DappInteraction {
	typealias NumberOfAccounts = P2P.Dapp.Request.NumberOfAccounts
}

// MARK: - FromLedgerDappMetadata
struct FromLedgerDappMetadata: Sendable, Hashable, Codable {
	static let defaultName = NonEmptyString(rawValue: L10n.DApp.Metadata.unknownName)!

	/// A dAppDefinition address is a valid `AccountAddress`
	let dAppDefinintionAddress: AccountAddress
	let origin: P2P.Dapp.Request.Metadata.Origin
	let name: NonEmpty<String>
	let description: String?

	init(
		dAppDefinintionAddress: AccountAddress,
		origin: P2P.Dapp.Request.Metadata.Origin,
		name: String?,
		description: String? = nil
	) {
		self.dAppDefinintionAddress = dAppDefinintionAddress
		self.origin = origin
		self.name = name.flatMap(NonEmptyString.init(rawValue:)) ?? Self.defaultName
		self.description = description
	}
}

// MARK: - DappContext
enum DappContext: Sendable, Hashable {
	/// The metadata sent with the request from the Dapp. Contains `origin` and `networkID`
	/// and possibly and invalid dAppDefinition address. We only allow this case `fromRequest`
	/// to be passed around if `isDeveloperModeEnabled` is `true`.
	case fromRequest(P2P.Dapp.Request.Metadata)

	/// A detailed DappMetaData fetched from Ledger.
	case fromLedger(FromLedgerDappMetadata)

	public var origin: P2P.Dapp.Request.Metadata.Origin {
		switch self {
		case let .fromLedger(metadata): return metadata.origin
		case let .fromRequest(metadata): return metadata.origin
		}
	}
}

#if DEBUG
extension DappContext {
	static let previewValue: Self = try! .fromLedger(.init(
		dAppDefinintionAddress: .init(address: "account_tdx_b_1p95nal0nmrqyl5r4phcspg8ahwnamaduzdd3kaklw3vqeavrwa"),
		origin: .init(rawValue: "https://radfi.com"),
		name: "Collabo.Fi",
		description: "A very collaby finance dapp"
	))
}
#endif

// MARK: - P2P.Dapp.Request.WalletRequestItem
extension P2P.Dapp.Request {
	/// A union type containing all request items allowed in a `WalletInteraction`, for app handling purposes.
	enum AnyInteractionItem: Sendable, Hashable {
		// requests
		case auth(AuthRequestItem)
		case ongoingAccounts(OngoingAccountsRequestItem)
		case ongoingPersonaData(OngoingPersonaDataRequestItem)
		case oneTimeAccounts(OneTimeAccountsRequestItem)
		case oneTimePersonaData(OneTimePersonaDataRequestItem)

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
				.auth(items.auth),
				items.ongoingAccounts.map(AnyInteractionItem.ongoingAccounts),
				items.ongoingPersonaData.map(AnyInteractionItem.ongoingPersonaData),
				items.oneTimeAccounts.map(AnyInteractionItem.oneTimeAccounts),
				items.oneTimePersonaData.map(AnyInteractionItem.oneTimePersonaData),
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
		case auth(AuthRequestResponseItem)
		case ongoingAccounts(OngoingAccountsRequestResponseItem)
		case ongoingPersonaData(OngoingPersonaDataRequestResponseItem)
		case oneTimeAccounts(OneTimeAccountsRequestResponseItem)
		case oneTimePersonaData(OneTimePersonaDataRequestResponseItem)

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
			var auth: AuthRequestResponseItem? = nil
			var ongoingAccounts: OngoingAccountsRequestResponseItem? = nil
			var ongoingPersonaData: OngoingPersonaDataRequestResponseItem? = nil
			var oneTimeAccounts: OneTimeAccountsRequestResponseItem? = nil
			var oneTimePersonaData: OneTimePersonaDataRequestResponseItem? = nil
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
				case let .oneTimePersonaData(item):
					oneTimePersonaData = item
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
							oneTimeAccounts: oneTimeAccounts,
							oneTimePersonaData: oneTimePersonaData
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
				case .auth:
					continue
				case .ongoingAccounts:
					continue
				case .ongoingPersonaData:
					continue
				case .oneTimeAccounts:
					continue
				case .oneTimePersonaData:
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
