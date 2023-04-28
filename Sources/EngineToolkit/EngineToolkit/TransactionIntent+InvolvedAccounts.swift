import EngineToolkitModels
import Prelude

extension TransactionIntent {
	public func accountsRequiredToSign() throws -> Set<AccountAddress_> {
		try manifest.accountsRequiredToSign(
			networkId: header.networkId
		)
	}
}
