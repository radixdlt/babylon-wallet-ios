import ClientPrelude

// MARK: - CreatePersonaRequest
public struct CreatePersonaRequest: Sendable, Hashable {
	public let overridingNetworkID: NetworkID?
	public let keychainAccessFactorSourcesAuthPrompt: String
	public let personaName: String?
	public let fields: IdentifiedArrayOf<OnNetwork.Persona.Field>

	public init(
		overridingNetworkID: NetworkID?,
		keychainAccessFactorSourcesAuthPrompt: String,
		personaName: String?,
		fields: IdentifiedArrayOf<OnNetwork.Persona.Field>
	) {
		self.overridingNetworkID = overridingNetworkID
		self.keychainAccessFactorSourcesAuthPrompt = keychainAccessFactorSourcesAuthPrompt
		self.personaName = personaName
		self.fields = fields
	}
}
