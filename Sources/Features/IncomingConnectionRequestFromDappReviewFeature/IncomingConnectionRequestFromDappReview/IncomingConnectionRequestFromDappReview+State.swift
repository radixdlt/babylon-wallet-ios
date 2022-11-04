import BrowserExtensionsConnectivityClient // RequestMethodWalletRequest, FIXME: extract models into seperate package
import Foundation
import Profile

// MARK: - IncomingConnectionRequestFromDappReview.State
public extension IncomingConnectionRequestFromDappReview {
	struct State: Equatable {
		/// needed for sending response back
		public let incomingMessageFromBrowser: IncomingMessageFromBrowser

		public let incomingConnectionRequestFromDapp: IncomingConnectionRequestFromDapp
		public var chooseAccounts: ChooseAccounts.State?

		public init(
			incomingMessageFromBrowser: IncomingMessageFromBrowser,
			incomingConnectionRequestFromDapp: IncomingConnectionRequestFromDapp,
			chooseAccounts: ChooseAccounts.State? = nil
		) {
			self.incomingMessageFromBrowser = incomingMessageFromBrowser
			self.incomingConnectionRequestFromDapp = incomingConnectionRequestFromDapp
			self.chooseAccounts = chooseAccounts
		}
	}
}

public extension IncomingConnectionRequestFromDappReview.State {
	init(
		incomingMessageFromBrowser: IncomingMessageFromBrowser,
		incomingConnectionRequestFromDapp: IncomingConnectionRequestFromDapp,
		accounts: [OnNetwork.Account]
	) {
		self.init(
			incomingMessageFromBrowser: incomingMessageFromBrowser,
			incomingConnectionRequestFromDapp: incomingConnectionRequestFromDapp,
			chooseAccounts: .init(
				incomingConnectionRequestFromDapp: incomingConnectionRequestFromDapp,
				accounts: .init(uniqueElements: accounts.map { .init(account: $0) })
			)
		)
	}
}

#if DEBUG
public extension RequestMethodWalletRequest {
	static let placeholderGetAccountAddressRequest = Self(
		method: .request,
		requestId: "deadbeef",
		payloads: [
			.accountAddresses(.init(
				requestType: .accountAddresses,
				numberOfAddresses: 1
			)
			),
		],
		metadata: .init(
			networkId: 1,
			dAppId: "RadarSwap"
		)
	)
}

public extension IncomingConnectionRequestFromDappReview.State {
	static let placeholder: Self = .init(
		incomingMessageFromBrowser: try! .init(requestMethodWalletRequest: .placeholderGetAccountAddressRequest, browserExtensionConnection: .placeholder),
		incomingConnectionRequestFromDapp: .placeholder
	)
}
#endif
