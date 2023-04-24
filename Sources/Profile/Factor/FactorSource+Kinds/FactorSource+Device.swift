import Cryptography
import EngineToolkit
import Prelude

// MARK: FactorSources
extension FactorSource {
	public static func device(
		mnemonic: Mnemonic,
		label: FactorSource.Label,
		description: FactorSource.Description,
		bip39Passphrase: String = "",
		olympiaCompatible: Bool,
		storage: Storage?
	) throws -> HDOnDeviceFactorSource {
		let factorSource = try Self(
			kind: .device,
			id: id(fromRoot: mnemonic.hdRoot(passphrase: bip39Passphrase)),
			label: label,
			description: description,
			parameters: olympiaCompatible ? .olympiaBackwardsCompatible : .babylon,
			storage: storage
		)
		return try HDOnDeviceFactorSource(factorSource: factorSource)
	}

	public static func babylon(
		mnemonic: Mnemonic,
		bip39Passphrase: String = "",
		label: FactorSource.Label = "iPhone",
		description: FactorSource.Description = "babylon"
	) throws -> BabylonDeviceFactorSource {
		let hdOnDeviceFactorSource = try Self.device(
			mnemonic: mnemonic,
			label: label, // will be changed by ProfileStore to *device* **name**
			description: description, // will be changed by ProfileStore to *device* **model**
			bip39Passphrase: bip39Passphrase,
			olympiaCompatible: false,
			storage: .entityCreating(.init())
		)
		return try BabylonDeviceFactorSource(hdOnDeviceFactorSource: hdOnDeviceFactorSource)
	}

	public static func babylon(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		label: FactorSource.Label = "iPhone",
		description: FactorSource.Description = "babylon"
	) throws -> BabylonDeviceFactorSource {
		try babylon(
			mnemonic: mnemonicWithPassphrase.mnemonic,
			bip39Passphrase: mnemonicWithPassphrase.passphrase,
			label: label,
			description: description
		)
	}

	public static func olympia(
		mnemonic: Mnemonic,
		bip39Passphrase: String = "",
		label: FactorSource.Label = "iPhone",
		description: FactorSource.Description = "olympia"
	) throws -> HDOnDeviceFactorSource {
		try device(
			mnemonic: mnemonic,
			label: label, // will be changed by ProfileStore to *device* **name**
			description: description, // will be changed by ProfileStore to *device* **model**
			bip39Passphrase: bip39Passphrase,
			olympiaCompatible: true,
			storage: nil
		)
	}

	public static func olympia(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		label: FactorSource.Label = "iPhone",
		description: FactorSource.Description = "olympia"
	) throws -> HDOnDeviceFactorSource {
		try olympia(
			mnemonic: mnemonicWithPassphrase.mnemonic,
			bip39Passphrase: mnemonicWithPassphrase.passphrase,
			label: label,
			description: description
		)
	}

	public static func trustedEntity(
		accountAddress: AccountAddress,
		label: FactorSource.Label,
		description: FactorSource.Description
	) throws -> Self {
		let hashInput = try Data(EngineToolkit().decodeAddressRequest(request: .init(address: accountAddress.address)).get().data)
		let factorSourceID = try ID(data: hashInput)
		return Self(
			kind: .trustedEntity,
			id: factorSourceID,
			label: label,
			description: description,
			parameters: .trustedEntity
		)
	}
}
