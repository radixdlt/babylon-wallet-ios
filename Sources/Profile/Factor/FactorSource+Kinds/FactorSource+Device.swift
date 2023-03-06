import Cryptography
import Prelude

// MARK: FactorSources
public extension FactorSource {
	static func device(
		mnemonic: Mnemonic,
		hint: NonEmptyString,
		bip39Passphrase: String = "",
		olympiaCompatible: Bool
	) throws -> Self {
		try Self(
			kind: .device,
			id: id(fromRoot: mnemonic.hdRoot(passphrase: bip39Passphrase)),
			hint: hint,
			parameters: olympiaCompatible ? .olympiaBackwardsCompatible : .babylon,
			storage: .forDevice(.init(nextDerivationIndicies: .init(forAccount: 0, forIdentity: 0)))
		)
	}

	static func babylon(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		hint: NonEmptyString = "babylon"
	) throws -> Self {
		try babylon(
			mnemonic: mnemonicWithPassphrase.mnemonic,
			bip39Passphrase: mnemonicWithPassphrase.passphrase,
			hint: hint
		)
	}

	static func babylon(
		mnemonic: Mnemonic,
		bip39Passphrase: String = "",
		hint: NonEmptyString = "babylon"
	) throws -> Self {
		try .device(
			mnemonic: mnemonic,
			hint: hint, // will be changed by ProfileStore to device model+name
			bip39Passphrase: bip39Passphrase,
			olympiaCompatible: false
		)
	}

	static func olympia(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		hint: NonEmptyString = "olympia"
	) throws -> Self {
		try olympia(
			mnemonic: mnemonicWithPassphrase.mnemonic,
			bip39Passphrase: mnemonicWithPassphrase.passphrase,
			hint: hint
		)
	}

	static func olympia(
		mnemonic: Mnemonic,
		bip39Passphrase: String = "",
		hint: NonEmptyString = "olympia"
	) throws -> Self {
		try device(
			mnemonic: mnemonic,
			hint: hint, // will be changed by ProfileStore to device model+name
			bip39Passphrase: bip39Passphrase,
			olympiaCompatible: true
		)
	}

	static func trustedContact(
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
