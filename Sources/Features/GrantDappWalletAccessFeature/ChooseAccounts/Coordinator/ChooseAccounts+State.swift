import ComposableArchitecture
import Foundation
import SharedModels

// MARK: - ChooseAccounts.State
public extension ChooseAccounts {
	struct State: Equatable {
		public let request: P2P.OneTimeAccountAddressesRequestToHandle

		public var canProceed: Bool
		public var accounts: IdentifiedArrayOf<ChooseAccounts.Row.State>

		public init(
			request: P2P.OneTimeAccountAddressesRequestToHandle,
			canProceed: Bool = false,
                        accounts: IdentifiedArrayOf<ChooseAccounts.Row.State> = []
		) {
			self.request = request

			self.canProceed = canProceed
			self.accounts = accounts
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
	static let placeholder: Self = .init(
		request: .init(requestItem: .placeholder, parentRequest: .placeholder),
		canProceed: false,
		accounts: .init(
			uniqueElements: [
				.placeholderOne,
			]
		)
	)
}
#endif
