import Cryptography
import Prelude

// MARK: FactorSources
extension FactorSource {
	public static func device(
		mnemonic: Mnemonic,
		hint: NonEmptyString,
		bip39Passphrase: String = "",
		olympiaCompatible: Bool
	) throws -> HDOnDeviceFactorSource {
		let factorSource = try Self(
			kind: .device,
			id: id(fromRoot: mnemonic.hdRoot(passphrase: bip39Passphrase)),
			hint: hint,
			parameters: olympiaCompatible ? .olympiaBackwardsCompatible : .babylon,
			storage: .forDevice(.init())
		)
		return try HDOnDeviceFactorSource(factorSource: factorSource)
	}

	public static func babylon(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		hint: NonEmptyString = "babylon"
	) throws -> HDOnDeviceFactorSource {
		try babylon(
			mnemonic: mnemonicWithPassphrase.mnemonic,
			bip39Passphrase: mnemonicWithPassphrase.passphrase,
			hint: hint
		)
	}

	public static func babylon(
		mnemonic: Mnemonic,
		bip39Passphrase: String = "",
		hint: NonEmptyString = "babylon"
	) throws -> HDOnDeviceFactorSource {
		try Self.device(
			mnemonic: mnemonic,
			hint: hint, // will be changed by ProfileStore to device model+name
			bip39Passphrase: bip39Passphrase,
			olympiaCompatible: false
		)
	}

	public static func olympia(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		hint: NonEmptyString = "olympia"
	) throws -> HDOnDeviceFactorSource {
		try olympia(
			mnemonic: mnemonicWithPassphrase.mnemonic,
			bip39Passphrase: mnemonicWithPassphrase.passphrase,
			hint: hint
		)
	}

	public static func olympia(
		mnemonic: Mnemonic,
		bip39Passphrase: String = "",
		hint: NonEmptyString = "olympia"
	) throws -> HDOnDeviceFactorSource {
		try device(
			mnemonic: mnemonic,
			hint: hint, // will be changed by ProfileStore to device model+name
			bip39Passphrase: bip39Passphrase,
			olympiaCompatible: true
		)
	}

	public static func trustedContact(
		publicKey: SLIP10.PublicKey,
		nameOfContact: NonEmpty<String>
	) throws -> Self {
		try Self(
			kind: .trustedContact,
			id: id(publicKey: publicKey),
			hint: nameOfContact,
			parameters: .default // unsure about this, should we pass `nil`?
		)
	}
}
