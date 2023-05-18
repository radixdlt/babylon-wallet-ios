import Foundation

// MARK: - FactorSourceKind
/// The **kind** (or "type") of FactorSource describes how it is used.
public enum FactorSourceKind:
	String,
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
	case ledgerHQHardwareWallet
}

extension FactorSourceKind {
	public var description: String {
		rawValue
	}

	public var isHD: Bool {
		switch self {
		case .device, .ledgerHQHardwareWallet: return true
		}
	}

	public var isOnDevice: Bool {
		switch self {
		case .device: return true
		case .ledgerHQHardwareWallet:
			return false
		}
	}

	public var isMine: Bool {
		switch self {
		case .device, .ledgerHQHardwareWallet: return true
		}
	}
}
