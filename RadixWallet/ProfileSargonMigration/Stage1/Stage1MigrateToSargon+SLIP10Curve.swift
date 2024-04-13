import Foundation
import Sargon

public typealias SLIP10Curve = Slip10Curve

extension SLIP10Curve {
	public init?(rawValue: String) {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

// MARK: Codable
extension SLIP10Curve: Codable {
	public init(from decoder: Decoder) throws {
		sargonProfileREMOVEAtEndOfStage1TEMP()
	}

	public func encode(to encoder: Encoder) throws {
		sargonProfileREMOVEAtEndOfStage1TEMP()
	}
}
