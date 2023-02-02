import EngineToolkitModels
import Prelude

public extension TransactionIntent {
	func accountsRequiredToSign() throws -> Set<ComponentAddress> {
		try manifest.accountsRequiredToSign(
			networkId: header.networkId
		)
	}
}
