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
			parameters: olympiaCompatible ? .olympiaBackwardsCompatible : .babylon
		)
	}

	@MainActor
	static func babylon(
		mnemonic: Mnemonic,
		bip39Passphrase: String = ""
	) throws -> Self {
		try .device(
			mnemonic: mnemonic,
			hint: Device.modelDescription(),
			bip39Passphrase: bip39Passphrase,
			olympiaCompatible: false
		)
	}

	@MainActor
	static func olympia(
		mnemonic: Mnemonic,
		bip39Passphrase: String = ""
	) throws -> Self {
		try .device(
			mnemonic: mnemonic,
			hint: Device.modelDescription(),
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
