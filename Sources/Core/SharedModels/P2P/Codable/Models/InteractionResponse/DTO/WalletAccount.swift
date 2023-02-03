import Cryptography
import Prelude
import ProfileModels

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
		public let label: NonEmpty<String>
		public let appearanceId: OnNetwork.Account.AppearanceID

		public init(
			accountAddress: AccountAddress,
			label: NonEmpty<String>,
			appearanceId: OnNetwork.Account.AppearanceID
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
	struct WalletAccountWithProof: Sendable, Hashable, Encodable {
		public let account: WalletAccount
		public let challenge: String
		public let signature: String
		public init(account: WalletAccount, challenge: String, signature: String) {
			self.account = account
			self.challenge = challenge
			self.signature = signature
		}
	}
}

public extension P2P.ToDapp.WalletAccount {
	init(account: OnNetwork.Account) {
		self.init(
			accountAddress: account.address,
			label: account.displayName,
			appearanceId: account.appearanceID
		)
	}
}
