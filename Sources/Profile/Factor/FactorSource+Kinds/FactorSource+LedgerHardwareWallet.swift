import Prelude

extension FactorSource {
	/// Just a namespace for Ledger Hardware wallet
	/// related types
	public enum LedgerHardwareWallet {
		public enum DeviceModel: String, Sendable, Hashable, Codable {
			case nanoS
			case nanoSPlus = "nanoS+"
			case nanoX
		}

		public enum SigningDisplayMode: String, Sendable, Hashable, Codable {
			case verbose
			case summary
			public static let `default`: Self = .verbose
		}
	}

	public static func ledger(
		id: FactorSource.ID,
		model: LedgerHardwareWallet.DeviceModel,
		name: String?
	) -> LedgerFactorSource {
		let factorSource = Self(
			kind: .ledgerHQHardwareWallet,
			id: id,
			label: .init(name ?? "Unnamed"),
			description: .init(model.rawValue),
			parameters: .olympiaBackwardsCompatible,
			storage: .entityCreating(.init()), // FIXME: Remove once we have multifactor, because once we have multi factor it should not be possible to create accounts controlled with Ledger, since no need, a user can add Ledger as another factor source when securifying the account
			addedOn: .now,
			lastUsedOn: .now
		)
		return try! LedgerFactorSource(factorSource: factorSource)
	}
}
