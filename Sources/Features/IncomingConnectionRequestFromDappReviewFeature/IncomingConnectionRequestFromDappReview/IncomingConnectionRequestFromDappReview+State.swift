import Foundation
import Profile
import SharedModels

// MARK: - IncomingConnectionRequestFromDappReview.State
public extension IncomingConnectionRequestFromDappReview {
	struct State: Equatable {
		public let request: P2P.OneTimeAccountAddressesRequestToHandle

		public var chooseAccounts: ChooseAccounts.State?

		public init(
			request: P2P.OneTimeAccountAddressesRequestToHandle,
			chooseAccounts: ChooseAccounts.State? = nil
		) {
			self.request = request
			self.chooseAccounts = chooseAccounts
		}
	}
}
