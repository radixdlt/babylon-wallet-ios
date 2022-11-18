import Foundation
import Profile
import SLIP10

// MARK: - P2P.ToDapp.WalletAccount
public extension P2P.ToDapp {
	/// Response to Dapp from wallet, info about a users account.
	///
	/// Called `AccountAddress` in [CAP21][cap]
	///
	/// [cap]: https://radixdlt.atlassian.net/wiki/spaces/AT/pages/2712895489/CAP-21+Message+format+between+dApp+and+wallet#Wallet-SDK-%E2%86%94%EF%B8%8F-Wallet-messages
	///
	struct WalletAccount: Sendable, Hashable, Encodable {
		public let address: String
		public let label: String
		public let appearanceID: OnNetwork.Account.AppearanceID

		public init(
			accountAddress: AccountAddress,
			label: String,
			appearanceID: OnNetwork.Account.AppearanceID
		) {
			address = accountAddress.address
			self.label = label
			self.appearanceID = appearanceID
		}
	}
}

public extension P2P.ToDapp.WalletAccount {
	init(account: OnNetwork.Account) {
		self.init(
			accountAddress: account.address,
			label: account.displayName ?? "Index: \(account.index)",
			appearanceID: account.appearanceID
		)
	}
}
