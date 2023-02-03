import CreateEntityFeature
import FeaturePrelude

// MARK: - ChooseAccounts.State
public extension ChooseAccounts {
	struct State: Hashable {
		public let requestKind: DappInteraction.RequestKind
		public let dappDefinitionAddress: DappDefinitionAddress
		public let dappMetadata: DappMetadata
		public let numberOfAccounts: DappInteraction.NumberOfAccounts
		public var availableAccounts: IdentifiedArrayOf<ChooseAccounts.Row.State>
		public var createAccountCoordinator: CreateAccountCoordinator.State?

		public init(
			requestKind: DappInteraction.RequestKind,
			dappDefinitionAddress: DappDefinitionAddress,
			dappMetadata: DappMetadata,
			numberOfAccounts: DappInteraction.NumberOfAccounts,
			availableAccounts: IdentifiedArrayOf<ChooseAccounts.Row.State> = [],
			createAccountCoordinator: CreateAccountCoordinator.State? = nil
		) {
			self.requestKind = requestKind
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
		requestKind: .oneTime,
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
