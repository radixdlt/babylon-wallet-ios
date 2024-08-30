// MARK: - EntitiesVisibilityClient
/// Controls the visibility of the entities in the Wallet
public struct EntitiesVisibilityClient: Sendable {
	public var hideAccount: HideAccount
	public var hidePersona: HidePersona
	public var unhideAccount: UnhideAccount
	public var unhidePersona: UnhidePersona
	public var getHiddenEntities: GetHiddenEntities
}

extension EntitiesVisibilityClient {
	public struct HiddenEntities: Hashable, Sendable {
		public let accounts: Accounts
		public let personas: Personas
	}

	public typealias HideAccount = @Sendable (Account.ID) async throws -> Void
	public typealias HidePersona = @Sendable (Persona.ID) async throws -> Void
	public typealias UnhideAccount = @Sendable (Account.ID) async throws -> Void
	public typealias UnhidePersona = @Sendable (Persona.ID) async throws -> Void
	public typealias GetHiddenEntities = @Sendable () async throws -> HiddenEntities
}
