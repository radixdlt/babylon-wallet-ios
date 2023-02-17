import Prelude

public enum LedgerHardwareModel: String, Sendable, Hashable {
	case nanoX = "Ledger Nano X"
	case nanoS = "Ledger Nano S"
	case nanoSPlus = "Ledger Nano S Plus"
	case stax = "Ledger Stax"
	public var hint: NonEmpty<String> {
		.init(rawValue: rawValue)!
	}
}
