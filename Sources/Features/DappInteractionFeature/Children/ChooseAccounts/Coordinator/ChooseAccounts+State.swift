import CreateAccountFeature
import FeaturePrelude

// MARK: - ChooseAccounts.State
public extension ChooseAccounts {
	struct State: Hashable {
		public enum Kind: Sendable, Hashable {
			case oneTime
			case ongoing
		}

		public let kind: Kind
		public let dappDefinitionAddress: DappDefinitionAddress
		public let dappMetadata: DappMetadata

		public let request: P2P.OneTimeAccountsRequestToHandle
		public var accounts: IdentifiedArrayOf<ChooseAccounts.Row.State>
		public var createAccountCoordinator: CreateAccountCoordinator.State?

		public init(
			kind: Kind,
			dappDefinitionAddress: DappDefinitionAddress,
			dappMetadata: DappMetadata,

			request: P2P.OneTimeAccountsRequestToHandle,
			accounts: IdentifiedArrayOf<ChooseAccounts.Row.State> = [],
			createAccountCoordinator: CreateAccountCoordinator.State? = nil
		) {
			self.kind = kind
			self.dappDefinitionAddress = dappDefinitionAddress
			self.dappMetadata = dappMetadata

			self.request = request
			self.accounts = accounts
			self.createAccountCoordinator = createAccountCoordinator
		}
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
		kind: .oneTime,
		dappDefinitionAddress: try! .init(address: "account_deadbeef"),
		dappMetadata: .previewValue,

		request: .init(request: .previewValueOneTimeAccountAccess)!,
		accounts: .init(
			uniqueElements: [
				.previewValueOne,
			]
		),
		createAccountCoordinator: nil
	)
}
#endif
