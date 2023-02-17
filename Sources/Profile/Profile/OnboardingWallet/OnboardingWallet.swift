import Cryptography
import Prelude
import ProfileModels

// MARK: - OnboardingWallet
public struct OnboardingWallet: Sendable, Hashable {
	/// A `device` FactorSource and its Mnemonic and passphrase unencrypted.
	public let privateFactorSource: PrivateHDFactorSource

	/// A new `Profile` containing the `device` `FactorSource` of `privateFactorSource`
	public let profile: Profile

	public init(
		privateFactorSource: PrivateHDFactorSource,
		profile: Profile
	) {
		precondition(profile.factorSources.contains(privateFactorSource.factorSource), "Discrepancy.")
		self.privateFactorSource = privateFactorSource
		self.profile = profile
	}
}
