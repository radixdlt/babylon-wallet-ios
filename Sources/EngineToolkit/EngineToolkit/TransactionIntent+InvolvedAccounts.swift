import EngineToolkitModels
import Prelude

extension TransactionIntent {
	public func accountsRequiredToSign() throws -> Set<ComponentAddress> {
		try manifest.accountsRequiredToSign(
			networkId: header.networkId
		)
	}
}
