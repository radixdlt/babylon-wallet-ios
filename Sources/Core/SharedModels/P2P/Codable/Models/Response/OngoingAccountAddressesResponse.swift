//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-11-16.
//

import Foundation
import NonEmpty

public extension P2P.ToDapp {
	/// Response to Dapp from wallet, info about a users accounts.
	///
	/// Called `OngoingAccountAddressesWithoutProofOfOwnershipResponse` in [CAP21][cap]
	///
	/// [cap]: https://radixdlt.atlassian.net/wiki/spaces/AT/pages/2712895489/CAP-21+Message+format+between+dApp+and+wallet#Wallet-SDK-%E2%86%94%EF%B8%8F-Wallet-messages
	///
	struct OngoingAccountAddressesResponse: Sendable, Hashable, Encodable {
		public let accountAddresses: [WalletAccount]
		public init(accountAddresses: NonEmpty<[WalletAccount]>) {
			self.accountAddresses = accountAddresses.rawValue
		}
	}
}
