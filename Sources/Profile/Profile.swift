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
		name: "Profile Placeholder",
		accounts: [
			.init(address: "c10erx8v19sd6gvggh7n6j4vsn", name: "Checking"),
			.init(address: "ktqt5oejnffadrf2k3571kxup5", name: "Savings"),
			.init(address: "pv6xujnk2yqt2w4ron9upgkpzo", name: "Shared"),
			.init(address: "sqkr9nv3ruyh94zrgaydj2rfv4", name: "Family"),
			.init(address: "bxmtia1vjospy55439lefycvg2", name: "Dummy 1"),
			.init(address: "3txy76hty9x6quokmo3ipnwi3l", name: "Dummy 2"),
			.init(address: "a6vl5xu149z71evhkftfedwtru", name: "Dummy 3"),
		]
	)
}
#endif
