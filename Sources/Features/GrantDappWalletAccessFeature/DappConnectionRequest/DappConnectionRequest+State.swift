import Foundation
import Profile
import SharedModels

// MARK: - DappConnectionRequest.State
public extension DappConnectionRequest {
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

public extension DappConnectionRequest.State {
	init(
		request: P2P.RequestFromClient,
		chooseAccounts: ChooseAccounts.State? = nil
	) throws {
		try self.init(
			request: .init(request: request),
			chooseAccounts: chooseAccounts
		)
	}
}
