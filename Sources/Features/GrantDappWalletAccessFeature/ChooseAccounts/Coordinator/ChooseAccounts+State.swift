import ComposableArchitecture
import CreateAccountFeature
import Foundation
import SharedModels

// MARK: - ChooseAccounts.State
public extension ChooseAccounts {
	struct State: Equatable {
		public let request: P2P.OneTimeAccountAddressesRequestToHandle
		public var canProceed: Bool
		public var accounts: IdentifiedArrayOf<ChooseAccounts.Row.State>
		public var createAccount: CreateAccount.State?

		public init(
			request: P2P.OneTimeAccountAddressesRequestToHandle,
			canProceed: Bool = false,
			accounts: IdentifiedArrayOf<ChooseAccounts.Row.State> = [],
			createAccount: CreateAccount.State? = nil
		) {
			self.request = request
			self.canProceed = canProceed
			self.accounts = accounts
			self.createAccount = createAccount
		}
	}
}

public extension ChooseAccounts.State {
	init(
		request: P2P.RequestFromClient
	) throws {
		try self.init(
			request: .init(request: request)
		)
	}
}

// MARK: - Computed Properties
extension ChooseAccounts.State {
	var selectedAccounts: [ChooseAccounts.Row.State] {
		accounts.filter(\.isSelected)
	}
}

#if DEBUG
public extension ChooseAccounts.State {
	static let previewValue: Self = .init(
		request: .init(requestItem: .previewValue, parentRequest: .previewValue),
		canProceed: false,
		accounts: .init(
			uniqueElements: [
				.previewValueOne,
			]
		),
		createAccount: nil
	)
}
#endif
