import Foundation
import Sargon

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
}
