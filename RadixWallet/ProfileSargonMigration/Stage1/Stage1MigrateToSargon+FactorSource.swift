import Foundation
import Sargon

// MARK: - FactorSource + Identifiable
extension FactorSource: Identifiable {
	public typealias ID = FactorSourceID
	public var id: ID {
		switch self {
		case let .device(value): FactorSourceID.hash(value: value.id)
		case let .ledger(value): FactorSourceID.hash(value: value.id)
		}
	}

	public func extract<F>(_ type: F.Type = F.self) -> F? where F: FactorSourceProtocol {
		F.extract(from: self)
	}

	public func extract<F>(as _: F.Type = F.self) throws -> F where F: FactorSourceProtocol {
		guard let extracted = extract(F.self) else {
			throw IncorrectFactorSourceType(expectedKind: F.kind, actualKind: kind)
		}
		return extracted
	}

	public var kind: FactorSourceKind {
		property(\.kind)
	}

	private func property<Property>(_ keyPath: KeyPath<any BaseFactorSourceProtocol, Property>) -> Property {
		switch self {
		case let .device(factorSource): factorSource[keyPath: keyPath]
		case let .ledger(factorSource): factorSource[keyPath: keyPath]
		}
	}
}

// MARK: - IncorrectFactorSourceType
public struct IncorrectFactorSourceType: Swift.Error {
	public let expectedKind: FactorSourceKind
	public let actualKind: FactorSourceKind
}
