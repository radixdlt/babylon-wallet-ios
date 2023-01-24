import CreateAccountFeature
import FeaturePrelude

// MARK: - ChooseAccounts.State
public extension ChooseAccounts {
	struct State: Equatable {
		public let request: P2P.OneTimeAccountsRequestToHandle
		public var accounts: IdentifiedArrayOf<ChooseAccounts.Row.State>
		public var createAccountCoordinator: CreateAccountCoordinator.State?

		public init(
			request: P2P.OneTimeAccountsRequestToHandle,
			accounts: IdentifiedArrayOf<ChooseAccounts.Row.State> = [],
			createAccountCoordinator: CreateAccountCoordinator.State? = nil
		) {
			self.request = request
			self.accounts = accounts
			self.createAccountCoordinator = createAccountCoordinator
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
		accounts: .init(
			uniqueElements: [
				.previewValueOne,
			]
		),
		createAccountCoordinator: nil
	)
}
#endif
