import ClientPrelude
import ProfileModels

public struct GetDerivationPathForNewEntityRequest: Sendable, Equatable {
	// if `nil` we will use current networkID
	public let networkID: NetworkID?
	public let factorSource: FactorSource
	public let entityKind: EntityKind
	public let keyKind: KeyKind

	public init(
		networkID: NetworkID?,
		factorSource: FactorSource,
		entityKind: EntityKind,
		keyKind: KeyKind
	) throws {
		guard factorSource.kind.isHD else {
			struct HDFactorSourceRequiredWhenUsedAsGenesisForEntity: Swift.Error {}
			throw HDFactorSourceRequiredWhenUsedAsGenesisForEntity()
		}
		self.networkID = networkID
		self.factorSource = factorSource
		self.entityKind = entityKind
		self.keyKind = keyKind
	}
}
