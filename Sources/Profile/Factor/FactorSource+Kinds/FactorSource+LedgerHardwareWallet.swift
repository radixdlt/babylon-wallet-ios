import Prelude

extension FactorSource {
	/// Just a namespace for Ledger Hardware wallet
	/// related types
	public enum LedgerHardwareWallet {
		public enum DeviceModel: String, Sendable, Hashable, Codable {
			case nanoS
			case nanoSPlus
			case nanoX
		}
	}

	public static func ledger(
		id: FactorSource.ID,
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
			id: id,
			hint: hint,
			parameters: olympiaCompatible ? .olympiaBackwardsCompatible : .babylon,
			storage: nil,
			addedOn: .now,
			lastUsedOn: .now
		)
	}
}
