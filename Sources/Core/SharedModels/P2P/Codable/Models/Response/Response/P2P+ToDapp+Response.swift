import Foundation

// MARK: - P2P.ToDapp.Response
public extension P2P.ToDapp {
	enum Response: Sendable, Hashable, Encodable, Identifiable {
		case success(Success)
		case failure(Failure)
	}
}

public extension P2P.ToDapp.Response {
	static func to(
		request: P2P.FromDapp.Request,
		items responseItems: [P2P.ToDapp.WalletResponseItem]
	) throws -> Self {
		guard responseItems.count == request.items.count else {
			throw InvalidNumberOfResponseItems()
		}
		return .success(.init(id: request.id, items: responseItems))
	}

	struct InvalidNumberOfResponseItems: Swift.Error {}
}

public extension P2P.ToDapp.Response {
	var id: P2P.FromDapp.Request.ID {
		switch self {
		case let .failure(failure):
			return failure.id
		case let .success(success):
			return success.id
		}
	}
}
