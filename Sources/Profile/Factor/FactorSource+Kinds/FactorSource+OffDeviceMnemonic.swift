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
			storage: nil
		)
		return try PrivateHDFactorSource(
			mnemonicWithPassphrase: mnemonicWithPassphrase,
			factorSource: factorSource
		)
	}
}
