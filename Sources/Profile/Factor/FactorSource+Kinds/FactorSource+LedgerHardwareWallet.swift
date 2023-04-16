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

	public static func ledger(
		deviceID: LedgerHardwareWallet.DeviceID,
		model: LedgerHardwareWallet.DeviceModel,
		name: NonEmptyString?,
		olympiaCompatible: Bool
	) throws -> Self {
		let hint: NonEmptyString = {
			if let name {
				return .init(rawValue: name.rawValue + " (\(model.rawValue))")!
			} else {
				return .init(rawValue: model.rawValue)!
			}
		}()

		return try Self(
			kind: .ledgerHQHardwareWallet,
			id: .init(hexCodable: deviceID.rawValue.data),
			hint: hint,
			parameters: olympiaCompatible ? .olympiaBackwardsCompatible : .babylon,
			storage: nil,
			addedOn: .now,
			lastUsedOn: .now
		)
	}
}
