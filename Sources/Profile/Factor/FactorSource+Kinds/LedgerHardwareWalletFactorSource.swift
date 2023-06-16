import CasePaths
import Prelude

// MARK: - LedgerHardwareWalletFactorSource
public struct LedgerHardwareWalletFactorSource: FactorSourceProtocol {
	public typealias ID = FactorSourceID.FromHash
	public let id: ID
	public var common: FactorSource.Common // We update `lastUsed`
	public let hint: Hint

	// FIXME: MFA remove (should not be able to create accounts using ledger when MFA)
	public var nextDerivationIndicesPerNetwork: NextDerivationIndicesPerNetwork?

	internal init(
		id: ID,
		common: FactorSource.Common,
		hint: Hint,
		nextDerivationIndicesPerNetwork: NextDerivationIndicesPerNetwork?
	) {
		precondition(id.kind == Self.kind)
		self.id = id
		self.common = common
		self.hint = hint
		self.nextDerivationIndicesPerNetwork = nextDerivationIndicesPerNetwork
	}
}

extension LedgerHardwareWalletFactorSource {
	/// Kind of factor source
	public static let kind: FactorSourceKind = .ledgerHQHardwareWallet
	public static let casePath: CasePath<FactorSource, Self> = /FactorSource.ledger
}

// MARK: LedgerHardwareWalletFactorSource.Hint
extension LedgerHardwareWalletFactorSource {
	public struct Hint: Sendable, Hashable, Codable {
		public typealias Model = LedgerHardwareWalletFactorSource.DeviceModel

		/// "Orange, scratched"
		public let name: String

		/// "nanoS+"
		public let model: Model

		public init(
			name: String,
			model: Model
		) {
			self.name = name
			self.model = model
		}
	}
}

// MARK: - LedgerHardwareWalletFactorSource
extension LedgerHardwareWalletFactorSource {
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

extension LedgerHardwareWalletFactorSource {
	/// Creates a factor source of `.ledger` kind with the specified
	/// Ledger model, name and `deviceID` (hash of public key)
	public static func model(
		_ model: DeviceModel,
		name: String,
		deviceID: HexCodable32Bytes
	) throws -> Self {
		try .init(
			id: ID(kind: .ledgerHQHardwareWallet, body: deviceID),
			common: Self.common(isOlympiaCompatible: true),
			hint: .init(name: name, model: model),
			nextDerivationIndicesPerNetwork: .init()
		)
	}
}
