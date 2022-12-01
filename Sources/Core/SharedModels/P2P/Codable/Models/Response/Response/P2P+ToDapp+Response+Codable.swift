import Foundation
public extension P2P.ToDapp.Response.Success {
	private enum CodingKeys: String, CodingKey {
		case id = "requestId"
		case items
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(items, forKey: .items)
		try container.encode(id, forKey: .id)
	}
}

public extension P2P.ToDapp.Response.Failure {
	private enum CodingKeys: String, CodingKey {
		case id = "requestId"
		case message
		case kind = "error"
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(id, forKey: .id)
		try container.encode(kind, forKey: .kind)
		try container.encodeIfPresent(message, forKey: .message)
	}
}

public extension P2P.ToDapp.Response {
	func encode(to encoder: Encoder) throws {
		switch self {
		case let .failure(failure):
			try failure.encode(to: encoder)
		case let .success(success):
			try success.encode(to: encoder)
		}
	}
}
