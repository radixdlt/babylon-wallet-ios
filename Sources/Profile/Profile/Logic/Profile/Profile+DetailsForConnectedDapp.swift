import Prelude

extension Profile {
	public func detailsForAuthorizedDapp(_ dapp: OnNetwork.AuthorizedDapp) throws -> OnNetwork.AuthorizedDappDetailed {
		let network = try onNetwork(id: dapp.networkID)
		return try network.detailsForAuthorizedDapp(dapp)
	}
}
