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
	public var links: OrderedSet<P2PLink>

	public init(_ links: OrderedSet<P2PLink>) {
		self.links = links
	}
}

// MARK: RandomAccessCollection
extension P2PLinks {
	public typealias Element = P2PLink

	public typealias Index = OrderedSet<P2PLink>.Index

	public typealias SubSequence = OrderedSet<P2PLink>.SubSequence

	public typealias Indices = OrderedSet<P2PLink>.Indices

	public var startIndex: Index {
		links.startIndex
	}

	public var indices: Indices {
		links.indices
	}

	public var endIndex: Index {
		links.endIndex
	}

	public func formIndex(after index: inout Index) {
		links.formIndex(after: &index)
	}

	public func formIndex(before index: inout Index) {
		links.formIndex(before: &index)
	}

	public subscript(bounds: Range<Index>) -> SubSequence {
		links[bounds]
	}

	public subscript(position: Index) -> Element {
		links[position]
	}
}

extension P2PLinks {
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		try self.init(.init(container.decode([P2PLink].self)))
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(links.elements)
	}
}

extension P2PLinks {
	public init(arrayLiteral elements: P2PLink...) {
		self.init(OrderedSet(elements))
	}
}

extension P2PLinks {
	public var _description: String {
		String(describing: links)
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
