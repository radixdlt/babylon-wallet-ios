import ClientPrelude
import Cryptography
import Profile

// MARK: - PersonasClient
public struct PersonasClient: Sendable {
	public var getPersonas: GetPersonas
	public var createUnsavedVirtualPersona: CreateUnsavedVirtualPersona
	public var saveVirtualPersona: SaveVirtualPersona

	public init(
		getPersonas: @escaping GetPersonas,
		createUnsavedVirtualPersona: @escaping CreateUnsavedVirtualPersona,
		saveVirtualPersona: @escaping SaveVirtualPersona
	) {
		self.getPersonas = getPersonas
		self.createUnsavedVirtualPersona = createUnsavedVirtualPersona
		self.saveVirtualPersona = saveVirtualPersona
	}
}

// MARK: PersonasClient.GetPersonas
extension PersonasClient {
	public typealias GetPersonas = @Sendable () async throws -> OnNetwork.Personas
	public typealias SaveVirtualPersona = @Sendable (OnNetwork.Persona) async throws -> Void
	public typealias CreateUnsavedVirtualPersona = @Sendable (CreateVirtualPersonaRequest) async throws -> OnNetwork.Persona
}

// MARK: - CreateVirtualPersonaRequest
public struct CreateVirtualPersonaRequest: CreateVirtualEntityRequestProtocol, Equatable {
	// if `nil` we will use current networkID
	public let networkID: NetworkID?

	// FIXME: change to shared HDFactorSource
	public let genesisFactorInstanceDerivationStrategy: GenesisFactorInstanceDerivationStrategy

	public let curve: Slip10Curve
	public let displayName: NonEmpty<String>
	public var entityKind: EntityKind { .identity }

	public init(
		curve: Slip10Curve,
		networkID: NetworkID?,
		genesisFactorInstanceDerivationStrategy: GenesisFactorInstanceDerivationStrategy,
		displayName: NonEmpty<String>
	) throws {
		self.curve = curve
		self.networkID = networkID
		self.genesisFactorInstanceDerivationStrategy = genesisFactorInstanceDerivationStrategy
		self.displayName = displayName
	}
}

extension PersonasClient {
	public func createUnsavedVirtualPersona(request: CreateVirtualEntityRequest) async throws -> OnNetwork.Persona {
		try await self.createUnsavedVirtualPersona(
			.init(
				curve: request.curve,
				networkID: request.networkID,
				genesisFactorInstanceDerivationStrategy: request.genesisFactorInstanceDerivationStrategy,
				displayName: request.displayName
			)
		)
	}
}
