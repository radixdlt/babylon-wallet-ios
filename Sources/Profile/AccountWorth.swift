import Foundation

public struct AccountWorth: Equatable {
	public let address: Profile.Account.Address
	public let worth: Float

	public init(
		address: Profile.Account.Address,
		worth: Float
	) {
		self.address = address
		self.worth = worth
	}
}
