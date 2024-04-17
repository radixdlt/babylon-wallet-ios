import Foundation
import Sargon

extension FactorSource {
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
		factorSourceKind
	}
}

// MARK: - IncorrectFactorSourceType
public struct IncorrectFactorSourceType: Swift.Error {
	public let expectedKind: FactorSourceKind
	public let actualKind: FactorSourceKind
}
