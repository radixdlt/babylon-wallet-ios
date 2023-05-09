import Cryptography
import Prelude
import Profile

// MARK: - P2P.Dapp.Response.WalletAccount
extension P2P.Dapp.Response {
	/// Response to Dapp from wallet, info about a users account.
	///
	/// Called `AccountAddress` in [CAP21][cap]
	///
	/// [cap]: https://radixdlt.atlassian.net/wiki/spaces/AT/pages/2712895489/CAP-21+Message+format+between+dApp+and+wallet#Wallet-SDK-%E2%86%94%EF%B8%8F-Wallet-messages
	///
	public struct WalletAccount: Sendable, Hashable, Encodable {
		public let address: String
		public let label: NonEmpty<String>
		public let appearanceId: Profile.Network.Account.AppearanceID

		public init(
			accountAddress: AccountAddress,
			label: NonEmpty<String>,
			appearanceId: Profile.Network.Account.AppearanceID
		) {
			address = accountAddress.address
			self.label = label
			self.appearanceId = appearanceId
		}
	}

	/// Response to Dapp from wallet, info about a users account.
	///
	/// Called `AccountAddressWithProofOfOwnership` in [CAP21][cap]
	///
	/// [cap]: https://radixdlt.atlassian.net/wiki/spaces/AT/pages/2712895489/CAP-21+Message+format+between+dApp+and+wallet#Wallet-SDK-%E2%86%94%EF%B8%8F-Wallet-messages
	///
	public struct WalletAccountWithProof: Sendable, Hashable, Encodable, Identifiable {
		public typealias ID = WalletAccount
		public var id: ID { account }
		public let account: WalletAccount

		public let proof: P2P.Dapp.AuthProof

		public init(
			account: WalletAccount,
			proof: P2P.Dapp.AuthProof
		) {
			self.account = account
			self.proof = proof
		}
	}
}

extension P2P.Dapp.Response.WalletAccount {
	public init(account: Profile.Network.Account) {
		self.init(
			accountAddress: account.address,
			label: account.displayName,
			appearanceId: account.appearanceID
		)
	}
}
