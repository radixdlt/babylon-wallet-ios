import Prelude

// MARK: - P2PLinks
/// Collection of clients user have connected P2P with, typically these
/// are WebRTC connections with DApps, but might be Android or iPhone
/// clients as well.
public struct P2PLinks:
	Sendable,
	Hashable,
	Codable,
	ExpressibleByArrayLiteral,
	CustomStringConvertible,
	RandomAccessCollection
{
	/// Ordered set of unique P2P connections made by the user with another client.
	public var clients: OrderedSet<P2PLink>

	public init(_ clients: OrderedSet<P2PLink>) {
		self.clients = clients
	}
}

// MARK: RandomAccessCollection
extension P2PLinks {
	public typealias Element = P2PLink

	public typealias Index = OrderedSet<P2PLink>.Index

	public typealias SubSequence = OrderedSet<P2PLink>.SubSequence

	public typealias Indices = OrderedSet<P2PLink>.Indices

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

extension P2PLinks {
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		try self.init(.init(container.decode([P2PLink].self)))
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(clients.elements)
	}
}

extension P2PLinks {
	public init(arrayLiteral elements: P2PLink...) {
		self.init(OrderedSet(elements))
	}
}

extension P2PLinks {
	public var _description: String {
		String(describing: clients)
	}

	public var description: String {
		_description
	}
}

// MARK: CustomDumpStringConvertible
extension P2PLinks: CustomDumpStringConvertible {
	public var customDumpDescription: String {
		_description
	}
}
