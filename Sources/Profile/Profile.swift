import Foundation

// MARK: - Profile
public struct Profile: Equatable {
	public let accounts: [Account]
	public let name: String

	public init(
		name: String = "Unnamed",
		accounts: [Account] = []
	) {
		self.name = name
		self.accounts = accounts
	}
}

#if DEBUG
public extension Profile {
	static let placeholder: Profile = .init(
		name: "Placeholder account",
		accounts: [
			.init(address: .random, name: "Checking"),
			.init(address: .random, name: "Savings"),
			.init(address: .random, name: "Shared"),
			.init(address: .random, name: "Family"),
			.init(address: .random, name: "Dummy 1"),
			.init(address: .random, name: "Dummy 2"),
			.init(address: .random, name: "Dummy 3"),
		]
	)
}
#endif
