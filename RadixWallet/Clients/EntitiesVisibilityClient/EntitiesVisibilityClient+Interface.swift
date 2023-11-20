// MARK: - EntitiesVisibilityClient
/// Controls the visibility of the entities in the Wallet
public struct EntitiesVisibilityClient: Sendable {
	public var hideAccounts: HideAccounts
	public var hidePersonas: HidePersonas
	public var unhideAllEntities: UnhideAllEntities
	public var getHiddenEntityCounts: GetHiddenEntityCounts
}

extension EntitiesVisibilityClient {
	public struct HiddenEntityCounts: Hashable, Sendable {
		public let hiddenAccountsCount: Int
		public let hiddenPersonasCount: Int
	}

	public typealias HideAccounts = @Sendable (Set<Profile.Network.Account.ID>) async throws -> Void
	public typealias HidePersonas = @Sendable (Set<Profile.Network.Persona.ID>) async throws -> Void
	public typealias UnhideAllEntities = @Sendable () async throws -> Void
	public typealias GetHiddenEntityCounts = @Sendable () async throws -> HiddenEntityCounts
}

extension EntitiesVisibilityClient {
	public func hideAccounts(ids: some Collection<Profile.Network.Account.ID>) async throws {
		try await hideAccounts(Set(ids))
	}

	public func hidePersonas(ids: some Collection<Profile.Network.Persona.ID>) async throws {
		try await hidePersonas(Set(ids))
	}

	public func hide(accounts: some Collection<Profile.Network.Account>) async throws {
		try await hideAccounts(ids: accounts.map(\.id))
	}

	public func hide(personas: some Collection<Profile.Network.Persona>) async throws {
		try await hidePersonas(ids: personas.map(\.id))
	}

	public func hide(account: Profile.Network.Account) async throws {
		try await hide(accounts: [account])
	}

	public func hide(persona: Profile.Network.Persona) async throws {
		try await hide(personas: [persona])
	}
}
