import Foundation
import GatewayAPI
import Profile

// MARK: - TransactionSigning.State
public extension TransactionSigning {
	struct State: Equatable {
		public var account: OnNetwork.Account
		public var transactionManifest: TransactionManifest

		public init(
			account: OnNetwork.Account,
			transactionManifest: TransactionManifest
		) {
			self.account = account
			self.transactionManifest = transactionManifest
		}
	}
}

#if DEBUG
public extension TransactionSigning.State {
//	static let placeholder: Self = .init()
}
#endif
