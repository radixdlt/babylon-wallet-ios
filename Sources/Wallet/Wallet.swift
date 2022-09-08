import Profile

public typealias Mnemonic = String

// MARK: - Wallet
public struct Wallet: Equatable {
	public var profile: Profile
	public let deviceFactorTypeMnemonic: Mnemonic

	public init(
		profile: Profile,
		deviceFactorTypeMnemonic: Mnemonic
	) {
		self.profile = profile
		self.deviceFactorTypeMnemonic = deviceFactorTypeMnemonic
	}
}

#if DEBUG
public extension Wallet {
	static let placeholder: Wallet = .init(profile: .placeholder, deviceFactorTypeMnemonic: "")
}
#endif
