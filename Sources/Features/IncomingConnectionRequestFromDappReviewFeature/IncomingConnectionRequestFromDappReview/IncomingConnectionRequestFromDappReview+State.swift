import BrowserExtensionsConnectivityClient // RequestMethodWalletRequest, FIXME: extract models into seperate package
import Foundation
import Profile

// MARK: - IncomingConnectionRequestFromDappReview.State
public extension IncomingConnectionRequestFromDappReview {
	struct State: Equatable {
		/// Need whole original request from dApp to be able to response back to dApp properly, I think.
		public let requestFromDapp: RequestMethodWalletRequest

		public let incomingConnectionRequestFromDapp: IncomingConnectionRequestFromDapp
		public var chooseAccounts: ChooseAccounts.State?

		public init(
			requestFromDapp: RequestMethodWalletRequest,
			incomingConnectionRequestFromDapp: IncomingConnectionRequestFromDapp,
			chooseAccounts: ChooseAccounts.State? = nil
		) {
			self.requestFromDapp = requestFromDapp
			self.incomingConnectionRequestFromDapp = incomingConnectionRequestFromDapp
			self.chooseAccounts = chooseAccounts
		}
	}
}

public extension IncomingConnectionRequestFromDappReview.State {
	init(
		requestFromDapp: RequestMethodWalletRequest,
		incomingConnectionRequestFromDapp: IncomingConnectionRequestFromDapp,
		accounts: [OnNetwork.Account]
	) {
		self.init(
			requestFromDapp: requestFromDapp,
			incomingConnectionRequestFromDapp: incomingConnectionRequestFromDapp,
			chooseAccounts: .init(
				incomingConnectionRequestFromDapp: incomingConnectionRequestFromDapp,
				accounts: .init(uniqueElements: accounts.map { .init(account: $0) })
			)
		)
	}
}

#if DEBUG
public extension IncomingConnectionRequestFromDappReview.State {
	static let placeholder: Self = .init(
		requestFromDapp: .init(
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
		),
		incomingConnectionRequestFromDapp: .placeholder
	)
}
#endif
