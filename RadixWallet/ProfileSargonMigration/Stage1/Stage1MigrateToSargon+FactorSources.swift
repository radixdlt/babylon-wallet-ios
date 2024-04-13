import Foundation
import Sargon

// MARK: - FactorSources + CollectionCompat
extension FactorSources: CollectionCompat {
	public typealias Element = FactorSource
	public var elements: [Element] {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

// MARK: - Accounts + CollectionCompat
extension Accounts: CollectionCompat {
	public typealias Element = Account
	public var elements: [Element] {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

// MARK: - Personas + CollectionCompat
extension Personas: CollectionCompat {
	public typealias Element = Persona
	public var elements: [Element] {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

// MARK: - AuthorizedDapps + CollectionCompat
extension AuthorizedDapps: CollectionCompat {
	public typealias Element = AuthorizedDapp
	public var elements: [Element] {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

// MARK: - CollectionCompat
public protocol CollectionCompat: Collection {
	var elements: [Element] { get }
}

extension CollectionCompat {
	public typealias Index = Array<Element>.Index

	public typealias SubSequence = Array<Element>.SubSequence

	public typealias Indices = Array<Element>.Indices

	public var startIndex: Index {
		elements.startIndex
	}

	public var indices: Indices {
		elements.indices
	}

	public var endIndex: Index {
		elements.endIndex
	}

	public func formIndex(after index: inout Index) {
		elements.formIndex(after: &index)
	}

	public func formIndex(before index: inout Index) {
		elements.formIndex(before: &index)
	}

	public subscript(bounds: Range<Index>) -> SubSequence {
		elements[bounds]
	}

	public subscript(position: Index) -> Element {
		elements[position]
	}
}
