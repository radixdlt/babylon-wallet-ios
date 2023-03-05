import Cryptography
import Prelude

// MARK: - Profile.Ephemeral
extension Profile {
	public struct Ephemeral: Sendable, Hashable {
		public private(set) var `private`: Private

		/// If this during startup an earlier Profile was found but we failed to load it.
		public let loadFailure: Profile.LoadingFailure?

		public init(
			private: Private,
			loadFailure: Profile.LoadingFailure?
		) {
			self.private = `private`
			self.loadFailure = loadFailure
		}

		/// E.g. when first account is created during onboarding.
		public mutating func updateProfile(_ profile: Profile) {
			`private`.updateProfile(profile)
		}
	}
}

// MARK: - Profile.Ephemeral.Private
extension Profile.Ephemeral {
	public struct Private: Sendable, Hashable {
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

		/// E.g. when first account is created during onboarding.
		public mutating func updateProfile(_ profile: Profile) {
			precondition(profile.id == self.profile.id)
			self.profile = profile
		}
	}
}

#if DEBUG
extension Profile.Ephemeral.Private {
	public static func testValue(hint: NonEmptyString) -> Self {
		let privateFS = PrivateHDFactorSource.testValue(hint: hint)
		let profile = Profile(factorSource: privateFS.factorSource, creatingDevice: hint)
		return Self(privateFactorSource: privateFS, profile: profile)
	}
}

extension Profile.Ephemeral {
	public static func testValue(
		hint: NonEmptyString,
		loadFailure: Profile.LoadingFailure? = nil
	) -> Self {
		.init(private: .testValue(hint: hint), loadFailure: loadFailure)
	}
}
#endif
