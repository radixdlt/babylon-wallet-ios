import CasePaths
import Prelude

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

		public init(name: Name, model: Model) {
			self.name = name
			self.model = model
		}
	}

	public var common: FactorSource.Common
	public var hint: Hint

	// FIXME: MFA remove (should not be able to create accounts using ledger when MFA)
	public var nextDerivationIndicesPerNetwork: NextDerivationIndicesPerNetwork?

	public init(
		common: FactorSource.Common,
		hint: Hint,
		nextDerivationIndicesPerNetwork: NextDerivationIndicesPerNetwork?
	) {
		self.common = common
		self.hint = hint
		self.nextDerivationIndicesPerNetwork = nextDerivationIndicesPerNetwork
	}
}

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
}
