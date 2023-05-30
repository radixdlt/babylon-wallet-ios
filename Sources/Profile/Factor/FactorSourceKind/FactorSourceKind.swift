import Foundation

// MARK: - FactorSourceKind
/// The **kind** (or "type") of FactorSource describes how it is used.
public enum FactorSourceKind:
	UInt8,
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible
{
	/// A user owned unencrypted mnemonic (and BIP39 passphrase) stored on device,
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

	/// A user owned mnemonic (and BIP39 passphrase) user has to input when used,
	/// e.g. during signing.
	///
	/// Attributes:
	///  * Mine
	///  * Off device
	///  * Hierarchical deterministic  (Mnemonic)
	case offDeviceMnemonic
}

extension FactorSourceKind {
	public var description: String {
		switch self {
		case .device: return "device"
		case .ledgerHQHardwareWallet: return "ledgerHQHardwareWallet"
		case .offDeviceMnemonic: return "offDeviceMnemonic"
		}
	}

	public var isHD: Bool {
		switch self {
		case .device, .ledgerHQHardwareWallet, .offDeviceMnemonic: return true
		}
	}

	public var isOnDevice: Bool {
		switch self {
		case .device: return true
		case .ledgerHQHardwareWallet, .offDeviceMnemonic:
			return false
		}
	}

	public var isMine: Bool {
		switch self {
		case .device, .ledgerHQHardwareWallet, .offDeviceMnemonic: return true
		}
	}
}
