import Prelude

// MARK: - P2PClients
/// Collection of clients user have connected P2P with, typically these
/// are WebRTC connections with DApps, but might be Android or iPhone
/// clients as well.
public struct P2PClients:
	Sendable,
	Hashable,
	Codable,
	ExpressibleByArrayLiteral,
	CustomStringConvertible,
	RandomAccessCollection
{
	/// Ordered set of unique P2P connections made by the user with another client.
	public var clients: OrderedSet<P2PClient>

	public init(_ clients: OrderedSet<P2PClient>) {
		self.clients = clients
	}
}

// MARK: RandomAccessCollection
public extension P2PClients {
	typealias Element = P2PClient

	typealias Index = OrderedSet<P2PClient>.Index

	typealias SubSequence = OrderedSet<P2PClient>.SubSequence

	typealias Indices = OrderedSet<P2PClient>.Indices

	var startIndex: Index {
		clients.startIndex
	}

	var indices: Indices {
		clients.indices
	}

	var endIndex: Index {
		clients.endIndex
	}

	func formIndex(after index: inout Index) {
		clients.formIndex(after: &index)
	}

	func formIndex(before index: inout Index) {
		clients.formIndex(before: &index)
	}

	subscript(bounds: Range<Index>) -> SubSequence {
		clients[bounds]
	}

	subscript(position: Index) -> Element {
		clients[position]
	}
}

public extension P2PClients {
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		try self.init(.init(container.decode([P2PClient].self)))
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(clients.elements)
	}
}

public extension P2PClients {
	init(arrayLiteral elements: P2PClient...) {
		self.init(OrderedSet(elements))
	}
}

public extension P2PClients {
	var _description: String {
		String(describing: clients)
	}

	var description: String {
		_description
	}
}

// MARK: CustomDumpStringConvertible
extension P2PClients: CustomDumpStringConvertible {
	public var customDumpDescription: String {
		_description
	}
}
