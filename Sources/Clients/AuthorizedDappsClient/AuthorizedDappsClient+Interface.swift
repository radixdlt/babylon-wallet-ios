import ClientPrelude
import Profile

// MARK: - AuthorizedDappsClient
public struct AuthorizedDappsClient: Sendable {
	public var getAuthorizedDapps: GetAuthorizedDapps
	public var addAuthorizedDapp: AddAuthorizedDapp
	public var forgetAuthorizedDapp: ForgetAuthorizedDapp
	public var updateAuthorizedDapp: UpdateAuthorizedDapp
	public var updateOrAddAuthorizedDapp: UpdateOrAddAuthorizedDapp
	public var disconnectPersonaFromDapp: DisconnectPersonaFromDapp
	public var detailsForAuthorizedDapp: DetailsForAuthorizedDapp

	public init(
		getAuthorizedDapps: @escaping GetAuthorizedDapps,
		addAuthorizedDapp: @escaping AddAuthorizedDapp,
		forgetAuthorizedDapp: @escaping ForgetAuthorizedDapp,
		updateAuthorizedDapp: @escaping UpdateAuthorizedDapp,
		updateOrAddAuthorizedDapp: @escaping UpdateOrAddAuthorizedDapp,
		disconnectPersonaFromDapp: @escaping DisconnectPersonaFromDapp,
		detailsForAuthorizedDapp: @escaping DetailsForAuthorizedDapp
	) {
		self.getAuthorizedDapps = getAuthorizedDapps
		self.addAuthorizedDapp = addAuthorizedDapp
		self.forgetAuthorizedDapp = forgetAuthorizedDapp
		self.updateAuthorizedDapp = updateAuthorizedDapp
		self.updateOrAddAuthorizedDapp = updateOrAddAuthorizedDapp
		self.disconnectPersonaFromDapp = disconnectPersonaFromDapp
		self.detailsForAuthorizedDapp = detailsForAuthorizedDapp
	}
}

extension AuthorizedDappsClient {
	public typealias GetAuthorizedDapps = @Sendable () async throws -> OnNetwork.AuthorizedDapps
	public typealias DetailsForAuthorizedDapp = @Sendable (OnNetwork.AuthorizedDapp) async throws -> OnNetwork.AuthorizedDappDetailed
	public typealias AddAuthorizedDapp = @Sendable (OnNetwork.AuthorizedDapp) async throws -> Void
	public typealias UpdateOrAddAuthorizedDapp = @Sendable (OnNetwork.AuthorizedDapp) async throws -> Void
	public typealias ForgetAuthorizedDapp = @Sendable (OnNetwork.AuthorizedDapp.ID, NetworkID) async throws -> Void
	public typealias UpdateAuthorizedDapp = @Sendable (OnNetwork.AuthorizedDapp) async throws -> Void
	public typealias DisconnectPersonaFromDapp = @Sendable (OnNetwork.Persona.ID, OnNetwork.AuthorizedDapp.ID, NetworkID) async throws -> Void
}

extension AuthorizedDappsClient {
	public func getDetailedDapp(
		_ id: OnNetwork.AuthorizedDapp.ID
	) async throws -> OnNetwork.AuthorizedDappDetailed {
		let dApps = try await getAuthorizedDapps()
		guard let dApp = dApps[id: id] else {
			throw AuthorizedDappDoesNotExists()
		}
		return try await detailsForAuthorizedDapp(dApp)
	}
}
