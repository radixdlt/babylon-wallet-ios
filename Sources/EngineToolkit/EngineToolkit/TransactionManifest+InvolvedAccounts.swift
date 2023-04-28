import Cryptography
import EngineToolkitModels
import Prelude

extension TransactionManifest {
	private func involvedAccounts(
		networkId: NetworkID,
		callMethodFilter: (CallMethod) -> Bool = { _ in true }
	) throws -> Set<AccountAddress_> {
		let analysis = try EngineToolkit()
			.extractAddressesFromManifest(request: .init(manifest: self, networkId: networkId))
			.get()
		return Set(analysis.accountAddresses)
	}

	public func accountsRequiredToSign(
		networkId: NetworkID
	) throws -> Set<AccountAddress_> {
		let analysis = try EngineToolkit()
			.extractAddressesFromManifest(request: .init(manifest: self, networkId: networkId))
			.get()
		return Set(analysis.accountsRequiringAuth)
	}

	public func accountsSuitableToPayTXFee(networkId: NetworkID) throws -> Set<AccountAddress_> {
		try involvedAccounts(
			networkId: networkId
		)
	}
}
