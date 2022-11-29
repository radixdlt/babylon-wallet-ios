import Collections
import Foundation

public extension P2P {
	typealias OneTimeAccountAddressesRequestToHandle = SpecificRequestItemToHandle<P2P.FromDapp.OneTimeAccountAddressesRequest>

	typealias SignTransactionRequestToHandle = SpecificRequestItemToHandle<P2P.FromDapp.SignTransactionRequest>

	/// A simple wrapper around a wallet request item to handle and its parent request.
	struct SpecificRequestItemToHandle<RequestItem: P2PFromDappWalletRequestItemProtocol>: Sendable, Hashable, Identifiable {
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

public extension P2P.OneTimeAccountAddressesRequestToHandle {
	init(request: P2P.RequestFromClient) throws {
		guard
			let oneTimeAccountRequest = request.requestFromDapp.items.compactMap(\.oneTimeAccountAddresses).first
		else {
			throw P2P.FromDapp.WalletRequestItem.ExpectedOneTimeAccountAddressesRequest()
		}

		self.init(
			requestItem: oneTimeAccountRequest,
			parentRequest: request
		)
	}
}

public extension P2P.SpecificRequestItemToHandle {
	typealias ID = P2P.RequestFromClient.ID
	var id: ID { parentRequest.id }
}

// MARK: - P2P.RequestItemToHandle
public extension P2P {
	/// A simple wrapper around a wallet request item to handle and its parent request.
	struct RequestItemToHandle: Sendable, Hashable, Identifiable {
		public let requestItem: P2P.FromDapp.WalletRequestItem
		public let parentRequest: P2P.RequestFromClient
		public init(requestItem: P2P.FromDapp.WalletRequestItem, parentRequest: P2P.RequestFromClient) {
			self.requestItem = requestItem
			self.parentRequest = parentRequest
		}
	}
}

public extension P2P.RequestItemToHandle {
	typealias ID = P2P.RequestFromClient.ID
	var id: ID { parentRequest.id }
}

#if DEBUG
public extension P2P.RequestItemToHandle {
	static let placeholderOneTimeAccount: Self = .init(
		requestItem: .oneTimeAccountAddresses(.placeholder),
		parentRequest: try! .init(
			requestFromDapp: .placeholderOneTimeAccount,
			client: .init(
				displayName: "Placeholder",
				connectionPassword: Data([0xDE, 0xAD])
			)
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
		guard !queued.contains(where: { $0.id == requestFromClient.id }) else { return }
		queued.append(.init(requestFromClient: requestFromClient))
	}

	mutating func rejected(request: P2P.RequestFromClient) -> P2P.ToDapp.Response {
		if current?.requestFromClient == request {
			current = nil
		}
		queued.removeAll(where: { $0.requestFromClient == request })
		return .reject(request: request.requestFromDapp)
	}

	mutating func finish(
		_ newlyFinished: P2P.FromDapp.WalletRequestItem,
		with responseItem: P2P.ToDapp.WalletResponseItem
	) -> P2P.ToDapp.Response? {
		if current == nil { preconditionFailure("Expected current") }
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
		queued.removeAll(where: { $0.id == nextUnfinished.id })
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
	struct UnfinishedRequestFromClient: Identifiable, Hashable {
		internal let requestFromClient: P2P.RequestFromClient
		internal private(set) var finishedResponseItems: [P2P.ToDapp.WalletResponseItem]
		internal private(set) var unfinishedRequestItems: [P2P.FromDapp.WalletRequestItem]

		internal init(requestFromClient: P2P.RequestFromClient) {
			self.requestFromClient = requestFromClient
			finishedResponseItems = []
			unfinishedRequestItems = requestFromClient.requestFromDapp.items
		}
	}
}

internal extension P2P.UnfinishedRequestFromClient {
	var requestFromDapp: P2P.FromDapp.Request { requestFromClient.requestFromDapp }
	typealias ID = P2P.RequestFromClient.ID
	var id: ID { requestFromDapp.id }

	struct AlreadyFinishItem: Swift.Error {}
	struct UnknownRequestItem: Swift.Error {}

	mutating func finish(
		_ newlyFinished: P2P.FromDapp.WalletRequestItem,
		with responseItem: P2P.ToDapp.WalletResponseItem
	) -> P2P.ToDapp.Response? {
		if !unfinishedRequestItems.contains(where: { $0 == newlyFinished }) {
//			throw UnknownRequestItem()
			preconditionFailure("Unknown request item")
		}
		if finishedResponseItems.contains(where: { $0 == responseItem }) {
//			throw AlreadyFinishItem()
			preconditionFailure("Finished already finished item")
		}
		unfinishedRequestItems.removeAll(where: { $0 == newlyFinished })
		finishedResponseItems.append(responseItem)

		guard unfinishedRequestItems.isEmpty else {
			return nil
		}

		do {
			return try P2P.ToDapp.Response.to(request: requestFromDapp, items: finishedResponseItems)
		} catch {
			assertionFailure("Failed to create response: \(error), discrepancy somewhere in implementation, please fix!")
			return nil
		}
	}
}
