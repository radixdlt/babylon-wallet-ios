import Prelude

// MARK: - LedgerFactorSource
/// This is NOT a `Codable` factor source, this is never saved anywhere, just in memory.
/// It acts a a convenience in code to not have to assert that `kind == .ledger` and
/// also creates `LedgerDevice` from `label` and `description`
public struct LedgerFactorSource: _ApplicationFactorSource {
	public static let assertedKind: FactorSourceKind = .ledgerHQHardwareWallet
	public static let assertedParameters: FactorSource.Parameters = .olympiaBackwardsCompatible

	public let factorSource: FactorSource

	public init(factorSource: FactorSource) throws {
		self.factorSource = try Self.validating(factorSource: factorSource)
		self.entityCreatingStorage = try factorSource.entityCreatingStorage()
	}

	public init(hdOnDeviceFactorSource: HDOnDeviceFactorSource) throws {
		try self.init(factorSource: hdOnDeviceFactorSource.factorSource)
	}
}

extension P2P.LedgerHardwareWallet.LedgerDevice {
	public init(factorSource: FactorSource) {
		self.init(
			name: .init(rawValue: factorSource.label.rawValue),
			id: factorSource.id.description,
			model: .init(from: factorSource)
		)
	}
}

extension P2P.LedgerHardwareWallet.Model {
	public init(from factorSource: FactorSource) {
		precondition(factorSource.kind == .ledgerHQHardwareWallet)
		self = Self(
			rawValue: factorSource.description.rawValue
		) ?? .nanoSPlus // FIXME: handle optional better.
	}
}
