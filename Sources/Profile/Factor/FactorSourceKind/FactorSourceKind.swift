import Foundation

// MARK: - FactorSourceKind
/// The **kind** (or "type") of FactorSource describes how it is used.
public enum FactorSourceKind:
	String,
	Sendable,
	Hashable,
	Codable,
	CaseIterable,
	Identifiable,
	CustomStringConvertible
{
	/// A user owned unencrypted mnemonic (and optional BIP39 passphrase) stored on device,
	/// thus directly usable. This kind is used as the standard factor source for all new
	/// wallet users.
	///
	/// Attributes:
	/// * Mine
	/// * On device
	/// * Hierarchical deterministic (Mnemonic)
	/// * Entity creating
	case device

	/// A user owned hardware wallet by vendor Ledger HQ, most commonly
	/// a Ledger Nano S or Ledger Nano X. Less common models are Ledger Nano S Plus
	/// Ledger Stax.
	///
	/// Attributes:
	/// * Mine
	/// * Off device
	/// * Hardware (requires Browser Connector Extension to communicate with wallet)
	/// * Hierarchical deterministic
	/// * Entity creating (accounts only) // FIXME: MFA remove
	case ledgerHQHardwareWallet

	/// A user owned mnemonic (and optional BIP39 passphrase) user has to input when used,
	/// e.g. during signing.
	///
	/// Attributes:
	///  * Mine
	///  * Off device
	///  * Hierarchical deterministic  (Mnemonic)
	case offDeviceMnemonic

	/// A contact, friend, company, organisation or otherwise third party the user trusts enought
	/// to be given a recovery token user has minted and sent the this contact.
	///
	/// Attributes:
	///  * **Not** mine
	///  * Off device
	case trustedContact

	/// An encrypted user owned mnemonic (*never* any BIP39 passphrase) which can
	/// be decrypted by answers to **security question**, which are personal questions
	/// that should be only known to the user.
	///
	/// Attributes:
	///  * Mine
	///  * Off device
	///  * Hierarchical deterministic  (**Encrypted** mnemonic)
	case securityQuestions
}

extension FactorSourceKind {
	public typealias ID = RawValue
	public var id: ID { rawValue }
}
