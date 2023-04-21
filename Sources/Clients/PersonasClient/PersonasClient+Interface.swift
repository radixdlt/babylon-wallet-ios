import ClientPrelude
import Cryptography
import Profile

// MARK: - PersonasClient
public struct PersonasClient: Sendable {
	public var personas: Personas
	public var getPersonas: GetPersonas
	public var updatePersona: UpdatePersona
	public var newUnsavedVirtualPersonaControlledByDeviceFactorSource: NewUnsavedVirtualPersonaControlledByDeviceFactorSource

	/// Creates a new virtual persona controlled by a `ledger` factor source, without saving it into the profile
	public var newUnsavedVirtualPersonaControlledByLedgerFactorSource: NewUnsavedVirtualPersonaControlledByLedgerFactorSource

	public var saveVirtualPersona: SaveVirtualPersona
	public var hasAnyPersonaOnAnyNetwork: HasAnyPersonaOnAnyNetworks

	public init(
		personas: @escaping Personas,
		getPersonas: @escaping GetPersonas,
		updatePersona: @escaping UpdatePersona,
		newUnsavedVirtualPersonaControlledByDeviceFactorSource: @escaping NewUnsavedVirtualPersonaControlledByDeviceFactorSource,
		newUnsavedVirtualPersonaControlledByLedgerFactorSource: @escaping NewUnsavedVirtualPersonaControlledByLedgerFactorSource,
		saveVirtualPersona: @escaping SaveVirtualPersona,
		hasAnyPersonaOnAnyNetwork: @escaping HasAnyPersonaOnAnyNetworks
	) {
		self.personas = personas
		self.getPersonas = getPersonas
		self.updatePersona = updatePersona
		self.newUnsavedVirtualPersonaControlledByDeviceFactorSource = newUnsavedVirtualPersonaControlledByDeviceFactorSource
		self.newUnsavedVirtualPersonaControlledByLedgerFactorSource = newUnsavedVirtualPersonaControlledByLedgerFactorSource
		self.saveVirtualPersona = saveVirtualPersona
		self.hasAnyPersonaOnAnyNetwork = hasAnyPersonaOnAnyNetwork
	}
}

// MARK: PersonasClient.GetPersonas
extension PersonasClient {
	public typealias Personas = @Sendable () async -> AnyAsyncSequence<Profile.Network.Personas>
	public typealias GetPersonas = @Sendable () async throws -> Profile.Network.Personas
	public typealias HasAnyPersonaOnAnyNetworks = @Sendable () async -> Bool
	public typealias UpdatePersona = @Sendable (Profile.Network.Persona) async throws -> Void
	public typealias SaveVirtualPersona = @Sendable (Profile.Network.Persona) async throws -> Void
	public typealias NewUnsavedVirtualPersonaControlledByDeviceFactorSource = @Sendable (CreateVirtualEntityControlledByDeviceFactorSourceRequest) async throws -> Profile.Network.Persona

	public typealias NewUnsavedVirtualPersonaControlledByLedgerFactorSource = @Sendable (CreateVirtualEntityControlledByLedgerFactorSourceRequest) async throws -> Profile.Network.Persona
}
