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
		name: String?,
		olympiaCompatible: Bool
	) -> Self {
		Self(
			kind: .ledgerHQHardwareWallet,
			id: id,
			label: .init(name ?? "Unnamed"),
			description: .init(model.rawValue),
			parameters: olympiaCompatible ? .olympiaBackwardsCompatible : .babylon,
			storage: .entityCreating(.init()), // FIXME: Remove once we have multifactor
			addedOn: .now,
			lastUsedOn: .now
		)
	}
}
