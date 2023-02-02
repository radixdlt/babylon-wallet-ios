import ClientPrelude
import ProfileModels

// MARK: - CreateVirtualEntityRequest
public struct CreateVirtualEntityRequest: Sendable, Equatable {
	// if `nil` we will use current networkID
	public let networkID: NetworkID?

	// FIXME: change to shared HDFactorSource
	public let factorSource: Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource

	public let entityKind: EntityKind
	public let displayName: String
	public let keychainAccessFactorSourcesAuthPrompt: String

	public init(
		networkID: NetworkID?,
		factorSource uncheckedFactorSource: any FactorSourceProtocol,
		entityKind: EntityKind,
		displayName: String,
		keychainAccessFactorSourcesAuthPrompt: String
	) throws {
		guard let factorSource = uncheckedFactorSource as? Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource else {
			struct HDFactorSourceRequiredWhenUsedAsGenesisForEntity: Swift.Error {}
			throw HDFactorSourceRequiredWhenUsedAsGenesisForEntity()
		}
		self.networkID = networkID
		self.factorSource = factorSource
		self.entityKind = entityKind
		self.displayName = displayName
		self.keychainAccessFactorSourcesAuthPrompt = keychainAccessFactorSourcesAuthPrompt
	}
}

public extension CreateVirtualEntityRequest {
	func getDerivationPathRequest() throws -> GetDerivationPathForNewEntityRequest {
		try .init(networkID: networkID, factorSource: factorSource, entityKind: entityKind, keyKind: .transactionSigningKey)
	}
}
