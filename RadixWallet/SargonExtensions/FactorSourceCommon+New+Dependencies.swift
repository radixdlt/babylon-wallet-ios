import Foundation
import Sargon

extension FactorSourceCommon {
	public static func new(
		cryptoParameters: FactorSourceCryptoParameters
	) throws -> Self {
		@Dependency(\.date) var date
		return .init(
			cryptoParameters: cryptoParameters,
			addedOn: date(),
			lastUsedOn: date(),
			flags: []
		)
	}
}
