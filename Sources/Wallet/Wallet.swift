import Profile

public struct Wallet: Equatable {
	public let profile: Profile
	public init(
		profile: Profile
	) {
		self.profile = profile
	}
}
