import Foundation

// MARK: - HDFactorSourceRequiredWhenUsedAsGenesisForEntity
public struct HDFactorSourceRequiredWhenUsedAsGenesisForEntity: Swift.Error {
	public let specifiedFactorSource: FactorSource
}

extension FactorSource {
	@discardableResult
	public func assertIsHD() throws -> Self {
		guard kind.isHD else {
			throw HDFactorSourceRequiredWhenUsedAsGenesisForEntity(
				specifiedFactorSource: self
			)
		}
		return self
	}
}
