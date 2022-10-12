import Address
public typealias _Address = Address

// MARK: - Profile.Account
public extension Profile {
	struct Account: Equatable {
		public typealias Address = _Address
		public let address: Address
		public let name: String

		public init(
			address: Address,
			name: String
		) {
			self.address = address
			self.name = name
		}
	}
}
