import Foundation
import Sargon

extension DeviceInfo: Codable {
	public func encode(to encoder: any Encoder) throws {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public init(from decoder: any Decoder) throws {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}
