import Cryptography
import EngineToolkit
import Prelude

// MARK: FactorSources
extension FactorSource {
	public static func offDeviceMnemonic(
		withPassphrase mnemonicWithPassphrase: MnemonicWithPassphrase,
		label: FactorSource.Label, // e.g.  "Like a story about a horse and a battery"
		description: FactorSource.Description // e.g. "Stored in the place where I played often with my friend A***"
	) throws -> PrivateHDFactorSource {
		let factorSource = try Self(
			kind: .offDeviceMnemonic,
			id: id(fromRoot: mnemonicWithPassphrase.hdRoot()),
			label: label,
			description: description,
			parameters: .babylon,
			storage: .offDeviceMnemonic(.init(
				wordCount: mnemonicWithPassphrase.mnemonic.wordCount,
				language: mnemonicWithPassphrase.mnemonic.language,
				usedBip39Passphrase: !mnemonicWithPassphrase.passphrase.isEmpty
			))
		)
		return try PrivateHDFactorSource(
			mnemonicWithPassphrase: mnemonicWithPassphrase,
			factorSource: factorSource
		)
	}
}
