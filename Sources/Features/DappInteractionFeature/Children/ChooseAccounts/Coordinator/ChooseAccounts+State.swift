import CreateAccountFeature
import FeaturePrelude

// MARK: - ChooseAccounts.State
public extension ChooseAccounts {
	struct State: Hashable {
		public enum Kind: Sendable, Hashable {
			case oneTime
			case ongoing
		}

		public typealias NumberOfAccounts = P2P.FromDapp.WalletInteraction.NumberOfAccounts

		public let kind: Kind
		public let dappDefinitionAddress: DappDefinitionAddress
		public let dappMetadata: DappMetadata
		public let numberOfAccounts: NumberOfAccounts
		public var availableAccounts: IdentifiedArrayOf<ChooseAccounts.Row.State>
		public var createAccountCoordinator: CreateAccountCoordinator.State?

		public init(
			kind: Kind,
			dappDefinitionAddress: DappDefinitionAddress,
			dappMetadata: DappMetadata,
			numberOfAccounts: NumberOfAccounts,
			availableAccounts: IdentifiedArrayOf<ChooseAccounts.Row.State> = [],
			createAccountCoordinator: CreateAccountCoordinator.State? = nil
		) {
			self.kind = kind
			self.dappDefinitionAddress = dappDefinitionAddress
			self.dappMetadata = dappMetadata
			self.numberOfAccounts = numberOfAccounts
			self.availableAccounts = availableAccounts
			self.createAccountCoordinator = createAccountCoordinator
		}
	}
}

// MARK: - Computed Properties
extension ChooseAccounts.State {
	var selectedAccounts: [ChooseAccounts.Row.State] {
		availableAccounts.filter(\.isSelected)
	}
}

#if DEBUG
public extension ChooseAccounts.State {
	static let previewValue: Self = .init(
		kind: .oneTime,
		dappDefinitionAddress: try! .init(address: "account_deadbeef"),
		dappMetadata: .previewValue,
		numberOfAccounts: .atLeast(2),
		availableAccounts: .init(
			uniqueElements: [
				.previewValueOne,
			]
		),
		createAccountCoordinator: nil
	)
}
#endif
