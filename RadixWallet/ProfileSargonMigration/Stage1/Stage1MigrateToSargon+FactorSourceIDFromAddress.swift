import Foundation
import Sargon

// MARK: - FactorSourceIdFromAddress + Codable
extension FactorSourceIdFromAddress: Codable {
	public init(from decoder: Decoder) throws {
		sargonProfileREMOVEAtEndOfStage1TEMP()
	}

	public func encode(to encoder: Encoder) throws {
		sargonProfileREMOVEAtEndOfStage1TEMP()
	}
}

extension FactorSourceIdFromAddress {
	public func embed() -> FactorSourceID {
		.address(value: self)
	}
}
