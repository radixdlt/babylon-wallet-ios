import CreateEntityFeature
import FeaturePrelude

// MARK: - ChooseAccounts.State
extension ChooseAccounts {
	struct State: Hashable {
		enum AccessKind: Sendable, Hashable {
			case ongoing
			case oneTime
		}

		let interactionItem: DappInteractionFlow.State.AnyInteractionItem! // TODO: @davdroman factor out onto Proxy reducer
		let accessKind: AccessKind
		let dappDefinitionAddress: DappDefinitionAddress
		let dappMetadata: DappMetadata
		let numberOfAccounts: DappInteraction.NumberOfAccounts
		var availableAccounts: IdentifiedArrayOf<ChooseAccounts.Row.State>
		var createAccountCoordinator: CreateAccountCoordinator.State?

		init(
			interactionItem: DappInteractionFlow.State.AnyInteractionItem!,
			accessKind: AccessKind,
			dappDefinitionAddress: DappDefinitionAddress,
			dappMetadata: DappMetadata,
			numberOfAccounts: DappInteraction.NumberOfAccounts,
			availableAccounts: IdentifiedArrayOf<ChooseAccounts.Row.State> = [],
			createAccountCoordinator: CreateAccountCoordinator.State? = nil
		) {
			self.interactionItem = interactionItem
			self.accessKind = accessKind
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
extension ChooseAccounts.State {
	static let previewValue: Self = .init(
		interactionItem: nil,
		accessKind: .oneTime,
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
