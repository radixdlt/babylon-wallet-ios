import Foundation
import Sargon

extension FiatCurrency: Codable {
	public init(from decoder: any Decoder) throws {
		sargonProfileStage1()
	}

	public func encode(to encoder: any Encoder) throws {
		sargonProfileStage1()
	}
}
