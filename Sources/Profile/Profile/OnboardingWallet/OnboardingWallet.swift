import Cryptography
import Prelude
import ProfileModels

// MARK: - EphemeralPrivateProfile
public struct EphemeralPrivateProfile: Sendable, Hashable {
	/// A `device` FactorSource and its Mnemonic and passphrase unencrypted.
	public private(set) var privateFactorSource: PrivateHDFactorSource

	/// A new `Profile` containing the `device` `FactorSource` of `privateFactorSource`
	public private(set) var profile: Profile

	public init(
		privateFactorSource: PrivateHDFactorSource,
		profile: Profile
	) {
		precondition(profile.factorSources.contains(privateFactorSource.factorSource), "Discrepancy.")
		self.privateFactorSource = privateFactorSource
		self.profile = profile
	}

	public mutating func update(deviceDescription: NonEmptyString) {
		profile.creatingDevice = deviceDescription
		privateFactorSource.factorSource.hint = deviceDescription
		var factorSources = profile.factorSources.rawValue
		factorSources[id: profile.factorSources.first.id]?.hint = deviceDescription
		profile.factorSources = .init(rawValue: factorSources)!
	}
}
