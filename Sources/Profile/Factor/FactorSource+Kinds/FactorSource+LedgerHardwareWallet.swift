import Prelude

extension FactorSource {
	/// Just a namespace for Ledger Hardware wallet
	/// related types
	public enum LedgerHardwareWallet {
		public typealias DeviceID = Tagged<Self, HexCodable32Bytes>

		public enum DeviceModel: String, Sendable, Hashable, Codable {
			case nanoS
			case nanoSPlus
			case nanoX
		}
	}
}
