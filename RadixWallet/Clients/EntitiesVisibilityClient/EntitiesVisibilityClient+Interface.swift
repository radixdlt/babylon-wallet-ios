// MARK: - EntitiesVisibilityClient
/// Controls the visibility of the entities in the Wallet
public struct EntitiesVisibilityClient: Sendable {
	public var hideAccount: HideAccount
	public var hidePersona: HidePersona
	public var unhideAllEntities: UnhideAllEntities
	public var getHiddenEntityCounts: GetHiddenEntityCounts
}

extension EntitiesVisibilityClient {
	public struct HiddenEntityCounts: Hashable, Sendable {
		public let hiddenAccountsCount: Int
		public let hiddenPersonasCount: Int
	}

	public typealias HideAccount = @Sendable (Profile.Network.Account) async throws -> Void
	public typealias HidePersona = @Sendable (Profile.Network.Persona) async throws -> Void
	public typealias UnhideAllEntities = @Sendable () async throws -> Void
	public typealias GetHiddenEntityCounts = @Sendable () async throws -> HiddenEntityCounts
}
