import Prelude

extension Profile {
	public func detailsForConnectedDapp(_ dapp: OnNetwork.ConnectedDapp) throws -> OnNetwork.ConnectedDappDetailed {
		let network = try onNetwork(id: dapp.networkID)
		return try network.detailsForConnectedDapp(dapp)
	}
}
