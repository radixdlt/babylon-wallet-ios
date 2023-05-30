import CasePaths
import Prelude

// MARK: - FactorSource.LedgerHardwareWallet
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

//	public static func ledger(
//		id: FactorSource.ID,
//		model: LedgerHardwareWallet.DeviceModel,
//		name: String?
//	) -> LedgerFactorSource {
//		let factorSource = Self(
//			kind: .ledgerHQHardwareWallet,
//			id: id,
//			label: .init(name ?? "Unnamed"),
//			description: .init(model.rawValue),
//			cryptoParameters: .olympiaBackwardsCompatible,
//			storage: .entityCreating(.init()), // FIXME: Remove once we have multifactor, because once we have multi factor it should not be possible to create accounts controlled with Ledger, since no need, a user can add Ledger as another factor source when securifying the account
//			addedOn: .now,
//			lastUsedOn: .now
//		)
//		return try! LedgerFactorSource(factorSource: factorSource)
//	}
}

// MARK: - LedgerHardwareWalletFactorSource
public struct LedgerHardwareWalletFactorSource: FactorSourceProtocol {
	/// Kind of factor source
	public static let kind: FactorSourceKind = .ledgerHQHardwareWallet
	public static let casePath: CasePath<FactorSource, Self> = /FactorSource.ledger

	public struct Hint: Sendable, Hashable, Codable {
		/// "Orange, scratched"
		public var name: Name; public typealias Name = Tagged<(Self, name: ()), String>

		/// "nanoS+"
		public var model: Model; public typealias Model = FactorSource.LedgerHardwareWallet.DeviceModel
	}

	public struct LedgerParameters: Sendable, Hashable, Codable {
		public var signingDisplayMode: FactorSource.LedgerHardwareWallet.SigningDisplayMode
	}

	public let common: FactorSource.Common
	public var hint: Hint

	// FIXME: MFA remove (should not be able to create accounts using ledger when MFA)
	public var nextDerivationIndicesPerNetwork: NextDerivationIndicesPerNetwork?
	public var ledgerParameters: LedgerParameters
}
