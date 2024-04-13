import Foundation
import Sargon

// MARK: - CollectionCompat
public protocol CollectionCompat: Collection {
	var list: [Element] { get }
}

// MARK: - FactorSources + CollectionCompat
extension FactorSources: CollectionCompat {
	public typealias Element = FactorSource
	public var list: [Element] {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

extension CollectionCompat {
	public typealias Index = Array<Element>.Index

	public typealias SubSequence = Array<Element>.SubSequence

	public typealias Indices = Array<Element>.Indices

	public var startIndex: Index {
		list.startIndex
	}

	public var indices: Indices {
		list.indices
	}

	public var endIndex: Index {
		list.endIndex
	}

	public func formIndex(after index: inout Index) {
		list.formIndex(after: &index)
	}

	public func formIndex(before index: inout Index) {
		list.formIndex(before: &index)
	}

	public subscript(bounds: Range<Index>) -> SubSequence {
		list[bounds]
	}

	public subscript(position: Index) -> Element {
		list[position]
	}
}
