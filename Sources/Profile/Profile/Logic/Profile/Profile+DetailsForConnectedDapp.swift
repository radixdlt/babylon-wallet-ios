import Prelude

extension Profile {
	public func detailsForConnectedDapp(_ dapp: OnNetwork.AuthorizedDapp) throws -> OnNetwork.ConnectedDappDetailed {
		let network = try onNetwork(id: dapp.networkID)
		return try network.detailsForConnectedDapp(dapp)
	}
}
