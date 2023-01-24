import Prelude

public extension P2P {
	typealias OneTimeAccountsRequestToHandle = SpecificRequestItemToHandle<P2P.FromDapp.WalletInteraction.OneTimeAccountsRequestItem>
	typealias SendTransactionToHandle = SpecificRequestItemToHandle<P2P.FromDapp.WalletInteraction.SendTransactionItem>

	/// A simple wrapper around a wallet request item to handle and its parent request.
	struct SpecificRequestItemToHandle<RequestItem: Sendable & Hashable>: Sendable, Hashable {
		public let requestItem: RequestItem
		public let parentRequest: P2P.RequestFromClient

		public init(
			requestItem: RequestItem,
			parentRequest: P2P.RequestFromClient
		) {
			self.requestItem = requestItem
			self.parentRequest = parentRequest
		}
	}
}

public extension P2P.OneTimeAccountsRequestToHandle {
	init?(request: P2P.RequestFromClient) {
		switch request.interaction.items {
		case let .request(.authorized(items)):
			if let item = items.oneTimeAccounts {
				self = .init(requestItem: item, parentRequest: request)
			}
		case let .request(.unauthorized(items)):
			if let item = items.oneTimeAccounts {
				self = .init(requestItem: item, parentRequest: request)
			}
		case .transaction:
			break
		}
		return nil
	}
}

// MARK: - P2P.RequestItemToHandle
// public extension P2P.SpecificRequestItemToHandle {
//	typealias ID = P2P.RequestFromClient.ID
//	var id: ID { parentRequest.id }
// }

public extension P2P {
	/// A simple wrapper around a wallet request item to handle and its parent request.
	struct RequestItemToHandle: Sendable, Hashable {
		public let requestItem: P2P.FromDapp.WalletInteraction.AnyInteractionItem
		public let parentRequest: P2P.RequestFromClient
		public init(requestItem: P2P.FromDapp.WalletInteraction.AnyInteractionItem, parentRequest: P2P.RequestFromClient) {
			self.requestItem = requestItem
			self.parentRequest = parentRequest
		}
	}
}

// public extension P2P.RequestItemToHandle {
//	typealias ID = P2P.RequestFromClient.ID
//	var id: ID { parentRequest.id }
// }

#if DEBUG
public extension P2P.RequestItemToHandle {
	static let previewValueOneTimeAccount: Self = .init(
		requestItem: .oneTimeAccounts(.previewValue),
		parentRequest: try! .init(
			originalMessage: .previewValue,
			interaction: .previewValueOneTimeAccount,
			client: .previewValue
		)
	)
}
#endif // DEBUG

// MARK: - P2P.UnfinishedRequestsFromClient
public extension P2P {
	struct UnfinishedRequestsFromClient: Hashable {
		private var current: UnfinishedRequestFromClient?
		private var queued: OrderedSet<UnfinishedRequestFromClient> = .init()
		public init() {}
	}
}

public extension P2P.UnfinishedRequestsFromClient {
	mutating func queue(requestFromClient: P2P.RequestFromClient) {
		guard !queued.contains(where: { $0.requestFromClient.interaction.id == requestFromClient.interaction.id }) else { return }
		queued.append(.init(requestFromClient: requestFromClient))
	}

	mutating func failed(interactionId: P2P.FromDapp.WalletInteraction.ID) {
		if current?.requestFromClient.interaction.id == interactionId {
			current = nil
		}
		queued.removeAll(where: { $0.requestFromClient.interaction.id == interactionId })
	}

	mutating func finish(
		_ newlyFinished: P2P.FromDapp.WalletInteraction.AnyInteractionItem,
		with responseItem: P2P.ToDapp.WalletInteractionSuccessResponse.AnyInteractionResponseItem
	) -> P2P.ToDapp.WalletInteractionResponse? {
		if current == nil {
			assertionFailure("Expected current")
			return nil
		}
		guard let finished = current?.finish(newlyFinished, with: responseItem) else {
			return nil
		}
		current = nil
		return finished
	}

	mutating func next() -> P2P.RequestItemToHandle? {
		guard let nextUnfinished = queued.first else {
			return nil
		}
		current = nextUnfinished
		guard let requestItem = nextUnfinished.unfinishedRequestItems.first else {
			assertionFailure("What? Do we need to handle requests with no request items? Or bad logic inside `UnfinishedRequestFromClient` type!")
			return nil
		}
		queued.removeAll(where: { $0.requestFromClient.interaction.id == nextUnfinished.requestFromClient.interaction.id })
		return .init(
			requestItem: requestItem,
			parentRequest: nextUnfinished.requestFromClient
		)
	}

	struct NoCurrentUnfinishedRequest: Swift.Error {}
	struct RequestContainsNoRequestItems: Swift.Error {}
}

// MARK: - P2P.UnfinishedRequestFromClient
internal extension P2P {
	/// Each request that comes into the wallet from e.g. a Dapp might contain several request items
	/// the wallet need to display each item and collect data/input from user/wallet to form a response
	/// item for each request item. Only once ALL request items have a corresponding response can should
	/// the wallet respond back with a `P2P.ToDapp.Response`. This data structure keeps track of all
	/// finished response items and unfinished requests items, for a given `P2P.FromDapp.Request`.
	struct UnfinishedRequestFromClient: Sendable, Hashable {
		internal let requestFromClient: P2P.RequestFromClient
		internal private(set) var finishedResponseItems: [P2P.ToDapp.WalletInteractionSuccessResponse.AnyInteractionResponseItem]
		internal private(set) var unfinishedRequestItems: [P2P.FromDapp.WalletInteraction.AnyInteractionItem]

		internal init(requestFromClient: P2P.RequestFromClient) {
			self.requestFromClient = requestFromClient
			finishedResponseItems = []
			unfinishedRequestItems = requestFromClient.interaction.erasedItems
		}
	}
}

internal extension P2P.UnfinishedRequestFromClient {
	struct AlreadyFinishItem: Swift.Error {}
	struct UnknownRequestItem: Swift.Error {}

	mutating func finish(
		_ newlyFinished: P2P.FromDapp.WalletInteraction.AnyInteractionItem,
		with responseItem: P2P.ToDapp.WalletInteractionSuccessResponse.AnyInteractionResponseItem
	) -> P2P.ToDapp.WalletInteractionResponse? {
		if !unfinishedRequestItems.contains(where: { $0 == newlyFinished }) {
//			throw UnknownRequestItem()
			assertionFailure("Unknown request item")
			return nil
		}
		if finishedResponseItems.contains(where: { $0 == responseItem }) {
//			throw AlreadyFinishItem()
			assertionFailure("Finished already finished item")
			return nil
		}
		unfinishedRequestItems.removeAll(where: { $0 == newlyFinished })
		finishedResponseItems.append(responseItem)

		guard unfinishedRequestItems.isEmpty else {
			return nil
		}

		let interaction = requestFromClient.interaction

		if
			let response = P2P.ToDapp.WalletInteractionSuccessResponse(
				for: interaction,
				with: finishedResponseItems
			)
		{
			return .success(response)
		} else {
			assertionFailure(
				"""
				Failed to create response for interaction:
				\(interaction)

				... with the following response items:
				\(finishedResponseItems)

				This is because the interaction is of type `transaction` but no `send` response item was collected.

				Please carefully check the implementation for potential code paths skipped by mistake.
				"""
			)
			return nil
		}
	}
}

public extension P2P.ToDapp.WalletInteractionSuccessResponse {
	init?(
		for interaction: P2P.FromDapp.WalletInteraction,
		with items: [P2P.ToDapp.WalletInteractionSuccessResponse.AnyInteractionResponseItem]
	) {
		switch interaction.items {
		case let .request(request):
			// NB: variadic generics + native case paths should greatly help to simplify this "picking" logic
			var auth: AuthRequestResponseItem? = nil
			var oneTimeAccounts: OneTimeAccountsRequestResponseItem? = nil
			for item in items {
				switch item {
				case let .auth(item):
					auth = item
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
						.authorized(
							.init(
								auth: auth,
								oneTimeAccounts: oneTimeAccounts
							)
						)
					)
				)
			} else {
				self.init(
					interactionId: interaction.id,
					items: .request(
						.unauthorized(
							.init(
								oneTimeAccounts: oneTimeAccounts
							)
						)
					)
				)
			}

		case let .transaction(transaction):
			var send: SendTransactionResponseItem? = nil
			for item in items {
				switch item {
				case .auth:
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
