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

		public mutating func update(deviceDescription: NonEmptyString) {
			`private`.update(deviceDescription: deviceDescription)
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

		public mutating func update(deviceDescription: NonEmptyString) {
			privateFactorSource.factorSource.update(deviceDescription: deviceDescription)
			profile.update(deviceDescription: deviceDescription)
		}
	}
}

extension FactorSource {
	public mutating func update(deviceDescription hint: NonEmptyString) {
		self.hint = hint
	}
}

extension Profile {
	public mutating func update(deviceDescription: NonEmptyString) {
		self.creatingDevice = deviceDescription
		var factorSources = self.factorSources.rawValue
		factorSources[id: self.factorSources.first.id]?.hint = deviceDescription
		self.factorSources = .init(rawValue: factorSources)!
	}
}
