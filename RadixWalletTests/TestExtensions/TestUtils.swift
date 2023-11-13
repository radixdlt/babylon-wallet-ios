import Foundation
@testable import Radix_Wallet_Dev

extension PrivateHDFactorSource {
	static let testValue = Self.testValueZooVote

	static let testValueZooVote: Self = testValue(mnemonicWithPassphrase: .testValueZooVote)
	static let testValueAbandonArt: Self = testValue(mnemonicWithPassphrase: .testValueAbandonArt)

	static func testValue(
		mnemonicWithPassphrase: MnemonicWithPassphrase
	) -> Self {
		withDependencies {
			$0.date = .constant(Date(timeIntervalSince1970: 0))
		} operation: {
			Self.testValue(
				name: deviceName,
				model: deviceModel,
				mnemonicWithPassphrase: mnemonicWithPassphrase
			)
		}
	}

	func hdRoot(derivationPath: DerivationPath) throws -> HierarchicalDeterministicFactorInstance {
		let hdRoot = try mnemonicWithPassphrase.hdRoot()

		let publicKey = try! hdRoot.derivePublicKey(
			path: derivationPath,
			curve: .curve25519
		)

		return HierarchicalDeterministicFactorInstance(
			id: factorSource.id,
			publicKey: publicKey,
			derivationPath: derivationPath
		)
	}
}

private let deviceName: String = "iPhone"
private let deviceModel: DeviceFactorSource.Hint.Model = "iPhone"
private let expectedDeviceDescription = DeviceInfo.deviceDescription(
	name: deviceName,
	model: deviceModel.rawValue
)

extension Mnemonic {
	static let testValue: Self = "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong"
}
