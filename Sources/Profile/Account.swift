import Foundation

public extension Profile {
	struct Account: Equatable {
		public let address: Address
		public var aggregatedValue: Float
		public let name: String

		public init(
			address: Address,
			aggregatedValue: Float,
			name: String
		) {
			self.address = address
			self.aggregatedValue = aggregatedValue
			self.name = name
		}
	}
}

public extension Profile.Account {
	typealias Address = String
}

#if DEBUG
public extension Profile.Account.Address {
	static var random: Self {
		let length = 26
		let characters = "abcdefghijklmnopqrstuvwxyz0123456789"
		return String((0 ..< length).map { _ in characters.randomElement()! })
	}
}
#endif
