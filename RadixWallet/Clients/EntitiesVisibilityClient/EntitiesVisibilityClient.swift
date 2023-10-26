import Foundation

// MARK: - EntitiesVisibilityClient
public struct EntitiesVisibilityClient: Sendable {
	public var hideAccount: HideAccount
	public var hidePersona: HidePersona
	public var unhideAllEntities: UnhideAllEntities
	public var getHiddenEntitiesStats: GetHiddenEntitiesStats
}

extension EntitiesVisibilityClient {
	public struct HiddenEntitiesStats: Hashable, Sendable {
		public let hiddenAccountsCount: Int
		public let hiddenPersonasCount: Int
	}

	public typealias HideAccount = @Sendable (Profile.Network.Account) async throws -> Void
	public typealias HidePersona = @Sendable (Profile.Network.Persona) async throws -> Void
	public typealias UnhideAllEntities = @Sendable () async throws -> Void
	public typealias GetHiddenEntitiesStats = @Sendable () async throws -> HiddenEntitiesStats
}

// MARK: DependencyKey
extension EntitiesVisibilityClient: DependencyKey {
	public typealias Value = EntitiesVisibilityClient

	public static let liveValue: Self = .live()

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		.init(
			hideAccount: { account in
				try await profileStore.updatingOnCurrentNetwork { network in
					network.hideAccount(account)
				}
			},
			hidePersona: { persona in
				try await profileStore.updatingOnCurrentNetwork { network in
					network.hidePersona(persona)
				}
			},
			unhideAllEntities: {
				try await profileStore.updatingOnCurrentNetwork { network in
					network.unhideAllEntities()
				}
			},
			getHiddenEntitiesStats: {
				let network = try await profileStore.network()

				return .init(
					hiddenAccountsCount: network.getHiddenAccounts().count,
					hiddenPersonasCount: network.getHiddenPersonas().count
				)
			}
		)
	}
}

extension DependencyValues {
	public var entitiesVisibilityClient: EntitiesVisibilityClient {
		get { self[EntitiesVisibilityClient.self] }
		set { self[EntitiesVisibilityClient.self] = newValue }
	}
}

// MARK: - EntitiesVisibilityClient + TestDependencyKey
extension EntitiesVisibilityClient: TestDependencyKey {
	public static let noop = Self(
		hideAccount: { _ in throw NoopError() },
		hidePersona: { _ in throw NoopError() },
		unhideAllEntities: { throw NoopError() },
		getHiddenEntitiesStats: { throw NoopError() }
	)
	public static let previewValue: Self = .noop
	public static let testValue = Self(
		hideAccount: unimplemented("\(Self.self).hideAccount"),
		hidePersona: unimplemented("\(Self.self).hidePersona"),
		unhideAllEntities: unimplemented("\(Self.self).unhideAllEntities"),
		getHiddenEntitiesStats: unimplemented("\(Self.self).getHiddenEntitiesStats")
	)
}
