import Foundation
import Sargon

// MARK: - FactorSources + NeverEmptyCollectionCompat
extension FactorSources: NeverEmptyCollectionCompat {
	public typealias Element = FactorSource
	public var elements: [Element] {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public init(elements: [Element]) throws {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

// MARK: - Accounts + CanBeEmptyCollectionCompat
extension Accounts: CanBeEmptyCollectionCompat {
	public typealias Element = Account
	public var elements: [Element] {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public init(elements: [Element]) {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

// MARK: - Personas + CanBeEmptyCollectionCompat
extension Personas: CanBeEmptyCollectionCompat {
	public typealias Element = Persona
	public var elements: [Element] {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public init(elements: [Element]) {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

// MARK: - AuthorizedDapps + CanBeEmptyCollectionCompat
extension AuthorizedDapps: CanBeEmptyCollectionCompat {
	public typealias Element = AuthorizedDapp
	public var elements: [Element] {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public init(elements: [Element]) {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

// MARK: - BaseCollectionCompat
public protocol BaseCollectionCompat: Sequence where Element: Identifiable {
	var elements: [Element] { get }
}

// MARK: - NeverEmptyCollectionCompat
public protocol NeverEmptyCollectionCompat: BaseCollectionCompat {
	init(elements: [Element]) throws
}

// MARK: - CanBeEmptyCollectionCompat
public protocol CanBeEmptyCollectionCompat: BaseCollectionCompat & ExpressibleByArrayLiteral {
	init(elements: [Element])
	init(identified: IdentifiedArrayOf<Element>)
}

extension CanBeEmptyCollectionCompat {
	public init(arrayLiteral elements: Element...) {
		self.init(elements: elements)
	}

	public init(identified: IdentifiedArrayOf<Element>) {
		self.init(elements: identified.elements)
	}
}

extension BaseCollectionCompat {
	public func asIdentified() -> IdentifiedArrayOf<Element> {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public func makeIterator() -> Iterator {
		elements.makeIterator()
	}

	public typealias Index = Array<Element>.Index

	public typealias SubSequence = Array<Element>.SubSequence

	public typealias Indices = Array<Element>.Indices
	public typealias Iterator = Array<Element>.Iterator

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
