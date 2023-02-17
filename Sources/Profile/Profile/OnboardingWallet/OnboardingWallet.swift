import Cryptography
import Prelude
import ProfileModels

// MARK: - OnboardingWallet
public struct OnboardingWallet: Sendable, Hashable {
//	public static func == (lhs: OnboardingWallet, rhs: OnboardingWallet) -> Bool {
//		lhs.privateFactorSource == rhs.privateFactorSource && lhs.profile == rhs.profile
//	}

	public let privateFactorSource: PrivateHDFactorSource
	public let profile: Profile
	public init(privateFactorSource: PrivateHDFactorSource, profile: Profile) throws {
		guard profile.containsFactorSource(
			withID: privateFactorSource.factorSource.id
		) else {
			preconditionFailure("discrepancy")
		}
		self.privateFactorSource = privateFactorSource
		self.profile = profile
	}
}

extension Profile {
	func containsFactorSource(withID id: FactorSourceID) -> Bool {
		factorSources.contains(where: { $0.id == id })
	}
}

public extension OnboardingWallet {
	static func new(bip39Passphrase: String = "") async throws -> Self {
		let mnemonic = try Mnemonic.generate()
		let mnemonicAndPassphrase = MnemonicWithPassphrase(
			mnemonic: mnemonic,
			passphrase: bip39Passphrase
		)
		let onDeviceFactorSource = try FactorSource.babylon(
			mnemonic: mnemonic,
			bip39Passphrase: bip39Passphrase
		)
		let privateFactorSource = try PrivateHDFactorSource(
			mnemonicWithPassphrase: mnemonicAndPassphrase,
			factorSource: onDeviceFactorSource
		)
		fixMultifactor()
		//        let profile = Profile(factorSource: onDeviceFactorSource)
//		return try await Self(
//			privateFactorSource: privateFactorSource,
//			profile: profile
//		)
	}
}
