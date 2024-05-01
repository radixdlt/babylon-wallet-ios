import Foundation

// MARK: - MnemonicHandling
public enum MnemonicHandling: String, CustomStringConvertible, Sendable, Hashable {
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

	public var description: String {
		rawValue
	}
}

// MARK: - DeviceFactorSourceControlled
public struct DeviceFactorSourceControlled: Sendable, CustomStringConvertible, Hashable {
	public let factorSourceID: FactorSourceIDFromHash
	public var mnemonicHandlingCallToAction: MnemonicHandling?

	public var description: String {
		if let mnemonicHandlingCallToAction {
			"mnemonicsCTA: \(mnemonicHandlingCallToAction), factorSourceID: \(factorSourceID)"
		} else {
			"factorSourceID: \(factorSourceID)"
		}
	}
}
