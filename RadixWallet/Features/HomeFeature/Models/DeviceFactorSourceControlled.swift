import Foundation

// MARK: - MnemonicHandling
public enum MnemonicHandling: Sendable, Hashable {
	/// Accounts has funds in them but user has not stated she has backed up the mnemonic controlling said account.
	case shouldBeExported

	/// Mnemonic missing for some accounts.
	case mustBeImported

	public var importMnemonicNeeded: Bool {
		self == .mustBeImported
	}

	public var exportMnemonicNeeded: Bool {
		self == .shouldBeExported
	}
}

// MARK: - DeviceFactorSourceControlled
public struct DeviceFactorSourceControlled: Sendable, Hashable {
	public let factorSourceID: FactorSourceID.FromHash
	public var mnemonicHandlingCallToAction: MnemonicHandling?
}
