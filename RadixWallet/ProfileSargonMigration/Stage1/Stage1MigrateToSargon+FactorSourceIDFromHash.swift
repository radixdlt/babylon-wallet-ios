import Foundation
import Sargon

// MARK: - FactorSourceIDFromHash + Codable
extension FactorSourceIDFromHash: Codable {
	public init(from decoder: Decoder) throws {
		sargonProfileREMOVEAtEndOfStage1TEMP()
	}

	public func encode(to encoder: Encoder) throws {
		sargonProfileREMOVEAtEndOfStage1TEMP()
	}
}

extension FactorSourceIdFromHash {
	public func embed() -> FactorSourceID {
		.hash(value: self)
	}
}
