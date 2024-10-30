import Foundation
import Sargon

// MARK: - AuthorizedDapp
typealias DappDefinitionAddress = AccountAddress

extension DappDefinitionAddress {
	/// This address is just a placeholder for now to be compatible with DappInteractor flow
	static let wallet = try! Self(
		validatingAddress: "account_tdx_21_128jk8476rq97wjv90nzjvr2nslpj04dcex7lh8tv80qvv8yfx59faw"
	)
}
