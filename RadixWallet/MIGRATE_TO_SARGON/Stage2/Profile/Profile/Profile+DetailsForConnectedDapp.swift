

extension Profile {
	public func detailsForAuthorizedDapp(_ dapp: AuthorizedDapp) throws -> AuthorizedDappDetailed {
		let network = try network(id: dapp.networkID)
		return try network.detailsForAuthorizedDapp(dapp)
	}
}
