
// MARK: - P2P.Dapp.Response.WalletAccount
extension P2P.Dapp.Response {
	/// Response to Dapp from wallet, info about a users account.
	///
	/// Called `AccountAddress` in [CAP21][cap]
	///
	/// [cap]: https://radixdlt.atlassian.net/wiki/spaces/AT/pages/2712895489/CAP-21+Message+format+between+dApp+and+wallet#Wallet-SDK-%E2%86%94%EF%B8%8F-Wallet-messages
	///
	public struct WalletAccount: Sendable, Hashable, Encodable {
		public let address: AccountAddress
		public let label: NonEmptyString
		public let appearanceId: AppearanceID

		public init(
			accountAddress: AccountAddress,
			label: NonEmptyString,
			appearanceId: AppearanceID
		) {
			self.address = accountAddress
			self.label = label
			self.appearanceId = appearanceId
		}
	}

	public struct AccountProof: Sendable, Hashable, Encodable {
		public let accountAddress: AccountAddress
		public let proof: P2P.Dapp.Response.AuthProof

		init(accountWithProof: P2P.Dapp.Response.Accounts.WithProof) {
			self.accountAddress = accountWithProof.account.address
			self.proof = accountWithProof.proof
		}
	}
}

extension P2P.Dapp.Response.WalletAccount {
	public init(account: Account) {
		self.init(
			accountAddress: account.address,
			label: account.displayName.asNonEmpty,
			appearanceId: account.appearanceID
		)
	}
}
