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
extension P2PClients {
	public typealias Element = P2PClient

	public typealias Index = OrderedSet<P2PClient>.Index

	public typealias SubSequence = OrderedSet<P2PClient>.SubSequence

	public typealias Indices = OrderedSet<P2PClient>.Indices

	public var startIndex: Index {
		clients.startIndex
	}

	public var indices: Indices {
		clients.indices
	}

	public var endIndex: Index {
		clients.endIndex
	}

	public func formIndex(after index: inout Index) {
		clients.formIndex(after: &index)
	}

	public func formIndex(before index: inout Index) {
		clients.formIndex(before: &index)
	}

	public subscript(bounds: Range<Index>) -> SubSequence {
		clients[bounds]
	}

	public subscript(position: Index) -> Element {
		clients[position]
	}
}

extension P2PClients {
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		try self.init(.init(container.decode([P2PClient].self)))
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(clients.elements)
	}
}

extension P2PClients {
	public init(arrayLiteral elements: P2PClient...) {
		self.init(OrderedSet(elements))
	}
}

extension P2PClients {
	public var _description: String {
		String(describing: clients)
	}

	public var description: String {
		_description
	}
}

// MARK: CustomDumpStringConvertible
extension P2PClients: CustomDumpStringConvertible {
	public var customDumpDescription: String {
		_description
	}
}
