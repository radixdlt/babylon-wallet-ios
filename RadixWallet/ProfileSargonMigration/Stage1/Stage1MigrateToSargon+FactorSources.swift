import Foundation
import Sargon

// MARK: - FactorSources + CollectionCompat
extension FactorSources: CollectionCompat {
	public typealias Element = FactorSource
	public var elements: [Element] {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public init(_ elements: [Element]) {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

// MARK: - Accounts + CollectionCompat
extension Accounts: CollectionCompat {
	public typealias Element = Account
	public var elements: [Element] {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public init(_ elements: [Element]) {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

// MARK: - Personas + CollectionCompat
extension Personas: CollectionCompat {
	public typealias Element = Persona
	public var elements: [Element] {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public init(_ elements: [Element]) {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

// MARK: - AuthorizedDapps + CollectionCompat
extension AuthorizedDapps: CollectionCompat {
	public typealias Element = AuthorizedDapp
	public var elements: [Element] {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public init(_ elements: [Element]) {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

// MARK: - CollectionCompat
public protocol CollectionCompat: RandomAccessCollection & ExpressibleByArrayLiteral {
	var elements: [Element] { get }
	init(_ elements: [Element])
}

extension CollectionCompat {
	public func asIdentified() -> IdentifiedArrayOf<Element> {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public typealias ArrayLiteralElement = Element
	public init(arrayLiteral elements: ArrayLiteralElement...) {
		self.init(elements)
	}

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
