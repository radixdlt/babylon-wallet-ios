

extension Profile {
	public func detailsForAuthorizedDapp(_ dapp: Profile.Network.AuthorizedDapp) throws -> Profile.Network.AuthorizedDappDetailed {
		let network = try network(id: dapp.networkID)
		return try network.detailsForAuthorizedDapp(dapp)
	}
}
