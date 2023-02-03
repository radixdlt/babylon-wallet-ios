import ClientPrelude
import ProfileModels

public struct GetDerivationPathForNewEntityRequest: Sendable, Equatable {
	// if `nil` we will use current networkID
	public let networkID: NetworkID?
	public let factorSource: Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource
	public let entityKind: EntityKind
	public let keyKind: KeyKind

	public init(
		networkID: NetworkID?,
		factorSource uncheckedFactorSource: any FactorSourceProtocol,
		entityKind: EntityKind,
		keyKind: KeyKind
	) throws {
		guard let factorSource = uncheckedFactorSource as? Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource else {
			struct HDFactorSourceRequiredWhenUsedAsGenesisForEntity: Swift.Error {}
			throw HDFactorSourceRequiredWhenUsedAsGenesisForEntity()
		}
		self.networkID = networkID
		self.factorSource = factorSource
		self.entityKind = entityKind
		self.keyKind = keyKind
	}
}
