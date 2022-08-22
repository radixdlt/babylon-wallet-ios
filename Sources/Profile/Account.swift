import Foundation

public extension Profile {
	struct Account: Equatable {
		public let address: Address
		public var aggregatedValue: Float
		public let currency: String // FIXME: use FiatCurrency instead of String
		public let name: String?

		public init(
			address: Address,
			aggregatedValue: Float,
			currency: String,
			name: String?
		) {
			self.address = address
			self.aggregatedValue = aggregatedValue
			self.currency = currency
			self.name = name
		}
	}
}

public extension Profile.Account {
	typealias Address = String
}
