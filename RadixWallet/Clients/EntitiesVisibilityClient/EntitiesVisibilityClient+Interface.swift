// MARK: - EntitiesVisibilityClient
/// Controls the visibility of the entities in the Wallet
struct EntitiesVisibilityClient: Sendable {
	var hideAccount: HideAccount
	var hidePersona: HidePersona
	var unhideAccount: UnhideAccount
	var unhidePersona: UnhidePersona
	var getHiddenEntities: GetHiddenEntities
}

extension EntitiesVisibilityClient {
	struct HiddenEntities: Hashable, Sendable {
		let accounts: Accounts
		let personas: Personas
	}

	typealias HideAccount = @Sendable (Account.ID) async throws -> Void
	typealias HidePersona = @Sendable (Persona.ID) async throws -> Void
	typealias UnhideAccount = @Sendable (Account.ID) async throws -> Void
	typealias UnhidePersona = @Sendable (Persona.ID) async throws -> Void
	typealias GetHiddenEntities = @Sendable () async throws -> HiddenEntities
}
