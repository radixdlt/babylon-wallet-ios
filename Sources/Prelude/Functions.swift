import Foundation

public func with<T>(
	_ initial: T,
	update: (inout T) throws -> Void
) rethrows -> T {
	var value = initial
	try update(&value)
	return value
}

// MARK: - PaginatedResourceContainer
@dynamicMemberLookup
public struct PaginatedResourceContainer<Container: RandomAccessCollection> {
	public var loaded: Container

	public var totalCount: Int?
	public var nextPageCursor: String?

	public init(loaded: Container, totalCount: Int? = nil, nextPageCursor: String? = nil) {
		self.loaded = loaded

		self.totalCount = totalCount
		self.nextPageCursor = nextPageCursor
	}
}

// MARK: RandomAccessCollection
extension PaginatedResourceContainer: RandomAccessCollection {
	public func index(before i: Index) -> Index {
		loaded.index(before: i)
	}

	public func index(after i: Index) -> Index {
		loaded.index(after: i)
	}

	public typealias Element = Container.Element
	public typealias Index = Container.Index
	public typealias SubSequence = Container.SubSequence
	public typealias Indices = Container.Indices

	public var indices: Indices {
		loaded.indices
	}

	public var startIndex: Index {
		loaded.startIndex
	}

	public var endIndex: Index {
		loaded.endIndex
	}

	public func formIndex(after index: inout Index) {
		loaded.formIndex(after: &index)
	}

	public func formIndex(before index: inout Index) {
		loaded.formIndex(before: &index)
	}

	public subscript(position: Index) -> Element {
		loaded[position]
	}

	public subscript(bounds: Range<Index>) -> SubSequence {
		loaded[bounds]
	}
}

extension PaginatedResourceContainer {
	public subscript<T>(dynamicMember keyPath: KeyPath<Container, T>) -> T {
		loaded[keyPath: keyPath]
	}
}

// MARK: Sendable
extension PaginatedResourceContainer: Sendable where Container: Sendable {}

// MARK: Equatable
extension PaginatedResourceContainer: Equatable where Container: Equatable {}

// MARK: Hashable
extension PaginatedResourceContainer: Hashable where Container: Hashable {}

// MARK: Codable
extension PaginatedResourceContainer: Codable where Container: Codable {}
