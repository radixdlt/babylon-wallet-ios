import ClientPrelude
import Profile

// MARK: - AuthorizedDappsClient
public struct AuthorizedDappsClient: Sendable {
	public var getAuthorizedDapps: GetAuthorizedDapps
	public var addAuthorizedDapp: AddAuthorizedDapp
	public var forgetAuthorizedDapp: ForgetAuthorizedDapp
	public var updateAuthorizedDapp: UpdateAuthorizedDapp
	public var updateOrAddAuthorizedDapp: UpdateOrAddAuthorizedDapp
	public var deauthorizePersonaFromDapp: DeauthorizePersonaFromDapp
	public var detailsForAuthorizedDapp: DetailsForAuthorizedDapp

	public init(
		getAuthorizedDapps: @escaping GetAuthorizedDapps,
		addAuthorizedDapp: @escaping AddAuthorizedDapp,
		forgetAuthorizedDapp: @escaping ForgetAuthorizedDapp,
		updateAuthorizedDapp: @escaping UpdateAuthorizedDapp,
		updateOrAddAuthorizedDapp: @escaping UpdateOrAddAuthorizedDapp,
		deauthorizePersonaFromDapp: @escaping DeauthorizePersonaFromDapp,
		detailsForAuthorizedDapp: @escaping DetailsForAuthorizedDapp
	) {
		self.getAuthorizedDapps = getAuthorizedDapps
		self.addAuthorizedDapp = addAuthorizedDapp
		self.forgetAuthorizedDapp = forgetAuthorizedDapp
		self.updateAuthorizedDapp = updateAuthorizedDapp
		self.updateOrAddAuthorizedDapp = updateOrAddAuthorizedDapp
		self.deauthorizePersonaFromDapp = deauthorizePersonaFromDapp
		self.detailsForAuthorizedDapp = detailsForAuthorizedDapp
	}
}

extension AuthorizedDappsClient {
	public typealias GetAuthorizedDapps = @Sendable () async throws -> Profile.Network.AuthorizedDapps
	public typealias DetailsForAuthorizedDapp = @Sendable (Profile.Network.AuthorizedDapp) async throws -> Profile.Network.AuthorizedDappDetailed
	public typealias AddAuthorizedDapp = @Sendable (Profile.Network.AuthorizedDapp) async throws -> Void
	public typealias UpdateOrAddAuthorizedDapp = @Sendable (Profile.Network.AuthorizedDapp) async throws -> Void
	public typealias ForgetAuthorizedDapp = @Sendable (Profile.Network.AuthorizedDapp.ID, NetworkID) async throws -> Void
	public typealias UpdateAuthorizedDapp = @Sendable (Profile.Network.AuthorizedDapp) async throws -> Void
	public typealias DeauthorizePersonaFromDapp = @Sendable (Profile.Network.Persona.ID, Profile.Network.AuthorizedDapp.ID, NetworkID) async throws -> Void
}

extension AuthorizedDappsClient {
	public func getDetailedDapp(
		_ id: Profile.Network.AuthorizedDapp.ID
	) async throws -> Profile.Network.AuthorizedDappDetailed {
		let dApps = try await getAuthorizedDapps()
		guard let dApp = dApps[id: id] else {
			throw AuthorizedDappDoesNotExists()
		}
		return try await detailsForAuthorizedDapp(dApp)
	}

	public func getDappsAuthorizedByPersona(
		_ id: Profile.Network.Persona.ID
	) async throws -> IdentifiedArrayOf<Profile.Network.AuthorizedDapp> {
		try await getAuthorizedDapps().filter { $0.referencesToAuthorizedPersonas.ids.contains(id) }
	}
}
