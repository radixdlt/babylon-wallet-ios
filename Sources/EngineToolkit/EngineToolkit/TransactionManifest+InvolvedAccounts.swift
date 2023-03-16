import Cryptography
import EngineToolkitModels
import Prelude

extension TransactionManifest {
	private func involvedAccounts(
		networkId: NetworkID,
		callMethodFilter: (CallMethod) -> Bool = { _ in true }
	) throws -> Set<ComponentAddress> {
		let analysis = try EngineToolkit()
			.analyzeManifest(request: .init(manifest: self, networkId: networkId))
			.get()
		return Set(analysis.accountAddresses)
	}

	public func accountsRequiredToSign(
		networkId: NetworkID
	) throws -> Set<ComponentAddress> {
		let analysis = try EngineToolkit()
			.analyzeManifest(request: .init(manifest: self, networkId: networkId))
			.get()
		return Set(analysis.accountsRequiringAuth)
	}

	public func accountsSuitableToPayTXFee(networkId: NetworkID) throws -> Set<ComponentAddress> {
		try involvedAccounts(
			networkId: networkId
		)
	}
}
