import Foundation
import Sargon

public typealias FactorSourceID = FactorSourceId

// MARK: - IncorrectFactorSourceIDType
public struct IncorrectFactorSourceIDType: Swift.Error {}

extension FactorSourceID {
	public func extract<F>(_ type: F.Type = F.self) -> F? where F: FactorSourceIDProtocol {
		F.extract(from: self)
	}

	public func extract<F>(as _: F.Type = F.self) throws -> F where F: FactorSourceIDProtocol {
		guard let extracted = extract(F.self) else {
			throw IncorrectFactorSourceIDType()
		}
		return extracted
	}
}
