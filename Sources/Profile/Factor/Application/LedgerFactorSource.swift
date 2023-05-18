import Prelude

// MARK: - LedgerFactorSource
/// This is NOT a `Codable` factor source, this is never saved anywhere, just in memory.
/// It acts a a convenience in code to not have to assert that `kind == .ledger` and
/// also `LedgerHardwareWallet.DeviceModel`
public struct LedgerFactorSource:
	_ApplicationFactorSource,

	// FIXME: Remove this protocol conformance once we have multifactor, because once we have multi factor it should not be possible to create accounts controlled with Ledger, since no need, a user can add Ledger as another factor source when securifying the account
	_EntityCreatingFactorSourceProtocol
{
	public static let assertedKind: FactorSourceKind = .ledgerHQHardwareWallet
	public static let assertedParameters: FactorSource.Parameters = .olympiaBackwardsCompatible

	public let factorSource: FactorSource
	public let model: FactorSource.LedgerHardwareWallet.DeviceModel

	// FIXME: Remove once we have multifactor, because once we have multi factor it should not be possible to create accounts controlled with Ledger, since no need, a user can add Ledger as another factor source when securifying the account
	public let entityCreatingStorage: FactorSource.Storage.EntityCreating

	public let name: String?

	public init(factorSource: FactorSource) throws {
		self.factorSource = try Self.validating(factorSource: factorSource)
		self.entityCreatingStorage = try factorSource.entityCreatingStorage()
		guard let model = FactorSource.LedgerHardwareWallet.DeviceModel(rawValue: factorSource.description.rawValue) else {
			throw UnrecognizedLedgerModel(model: factorSource.description.rawValue)
		}
		self.model = model
		self.name = factorSource.label.rawValue
	}
}

// MARK: - UnrecognizedLedgerModel
public struct UnrecognizedLedgerModel: Error {
	public let model: String
	public init(model: String) {
		self.model = model
	}
}
