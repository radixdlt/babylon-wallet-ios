import DappInteractionClient
import EngineToolkitClient
import FeaturePrelude

// MARK: - AssetTransfer
public struct AssetTransfer: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var accounts: TransferAccountList.State
		public var message: AssetTransferMessage.State?

		public init(from account: Profile.Network.Account) {
			self.accounts = .init(fromAccount: account)
			self.message = nil
		}
	}

	@Dependency(\.dappInteractionClient) var dappInteractionClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.engineToolkitClient) var engineToolkitClient

	public init() {}

	public enum ViewAction: Equatable, Sendable {
		case closeButtonTapped
		case addMessageTapped
		case sendTransferTapped
	}

	public enum ChildAction: Equatable, Sendable {
		case message(AssetTransferMessage.Action)
		case accounts(TransferAccountList.Action)
	}

	public enum DelegateAction: Equatable, Sendable {
		case dismissed
	}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.accounts, action: /Action.child .. ChildAction.accounts) {
			TransferAccountList()
		}
		Reduce(core)
			.ifLet(\.message, action: /Action.child .. ChildAction.message) {
				AssetTransferMessage()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .addMessageTapped:
			state.message = .empty
			return .none

		case .sendTransferTapped:
			do {
				let manifest = try createManifest(state)
				dappInteractionClient.addWalletInteraction(
					.transaction(.init(
						send: .init(
							version: .default,
							transactionManifest: manifest,
							message: state.message?.message
						)
					))
				)
			} catch {
				errorQueue.schedule(error)
				return .none
			}
			return .send(.delegate(.dismissed))

		case .closeButtonTapped:
			return .send(.delegate(.dismissed))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .message(.delegate(.removed)):
			state.message = nil
			return .none
		default:
			return .none
		}
	}
}

extension AssetTransfer.State {
	public var canSendTransferRequest: Bool {
		guard !accounts.receivingAccounts.isEmpty else {
			return false
		}

		return accounts.receivingAccounts.allSatisfy {
			guard $0.account != nil else {
				return false
			}
			let fungibleAssets = $0.assets.compactMap(/ResourceAsset.State.fungibleAsset)
			let nonFungibleAssets = $0.assets.compactMap(/ResourceAsset.State.nonFungibleAsset)

			if !fungibleAssets.isEmpty {
				return fungibleAssets.allSatisfy { $0.transferAmount != nil && $0.totalTransferSum <= $0.balance }
			}

			return !nonFungibleAssets.isEmpty
		}
	}
}

extension AssetTransfer {
	private struct InvolvedFungibleResource: Identifiable {
		struct PerAccountAmount: Identifiable {
			var id: AccountAddress
			var amount: BigDecimal
		}

		var id: ResourceAddress {
			address
		}

		let address: ResourceAddress
		let totalTransferAmount: BigDecimal
		var accounts: IdentifiedArrayOf<PerAccountAmount>
	}

	private struct InvolvedNonFungibleResource: Identifiable {
		struct PerAccountTokens: Identifiable {
			var id: AccountAddress
			var tokens: IdentifiedArrayOf<AccountPortfolio.NonFungibleResource.NonFungibleToken>
		}

		var id: ResourceAddress {
			address
		}

		let address: ResourceAddress
		var accounts: IdentifiedArrayOf<PerAccountTokens>

		var allTokens: [AccountPortfolio.NonFungibleResource.NonFungibleToken] {
			accounts.flatMap(\.tokens)
		}
	}

	private func createManifest(_ state: State) throws -> TransactionManifest {
		let involvedFungibleResources = extractInvolvedFungibleResources(state.accounts.receivingAccounts)
		let fungiblesTransferInstruction = try involvedFungibleResources.flatMap {
			try fungibleResourceTransferInstruction(witdhrawAccount: state.accounts.fromAccount.address, $0)
		}

		let involvedNonFungibles = extractInvolvedNonFungibleResource(state.accounts.receivingAccounts)
		let nonFungiblesTransferInstruction = try involvedNonFungibles.flatMap {
			try nonFungibleResourceTransferInstruction(witdhrawAccount: state.accounts.fromAccount.address, $0)
		}

		let allInstructions = fungiblesTransferInstruction + nonFungiblesTransferInstruction
		let manifest = TransactionManifest(instructions: .parsed(allInstructions.map { $0.embed() }))

		return try engineToolkitClient.convertManifestToString(.init(
			version: .default,
			networkID: .default,
			manifest: manifest
		))
	}

	private func extractInvolvedFungibleResources(
		_ receivingAccounts: IdentifiedArrayOf<ReceivingAccount.State>
	) -> IdentifiedArrayOf<InvolvedFungibleResource> {
		var resources: IdentifiedArrayOf<InvolvedFungibleResource> = []

		for receivingAccount in receivingAccounts {
			guard let accountAddress = receivingAccount.account?.id else {
				continue
			}
			for fungibleAsset in receivingAccount.assets.compactMap(/ResourceAsset.State.fungibleAsset) {
				guard let transferAmount = fungibleAsset.transferAmount else {
					continue
				}
				let accountTransfer = InvolvedFungibleResource.PerAccountAmount(
					id: accountAddress,
					amount: transferAmount
				)

				if resources[id: fungibleAsset.resource.resourceAddress] != nil {
					resources[id: fungibleAsset.resource.resourceAddress]?.accounts.append(accountTransfer)
				} else {
					resources.append(.init(
						address: fungibleAsset.resource.resourceAddress,
						totalTransferAmount: fungibleAsset.totalTransferSum,
						accounts: [accountTransfer]
					))
				}
			}
		}

		return resources
	}

	private func extractInvolvedNonFungibleResource(
		_ receivingAccounts: IdentifiedArrayOf<ReceivingAccount.State>
	) -> IdentifiedArrayOf<InvolvedNonFungibleResource> {
		var resources: IdentifiedArrayOf<InvolvedNonFungibleResource> = []

		for receivingAccount in receivingAccounts {
			guard let accountAddress = receivingAccount.account?.id else {
				continue
			}

			for nonFungibleAsset in receivingAccount.assets.compactMap(/ResourceAsset.State.nonFungibleAsset) {
				if resources[id: nonFungibleAsset.resourceAddress] != nil {
					if resources[id: nonFungibleAsset.resourceAddress]?.accounts[id: accountAddress] != nil {
						resources[id: nonFungibleAsset.resourceAddress]?.accounts[id: accountAddress]?.tokens.append(nonFungibleAsset.nftToken)
					} else {
						resources[id: nonFungibleAsset.resourceAddress]?.accounts.append(.init(id: accountAddress, tokens: [nonFungibleAsset.nftToken]))
					}
				} else {
					resources.append(.init(address: nonFungibleAsset.resourceAddress, accounts: [.init(id: accountAddress, tokens: [nonFungibleAsset.nftToken])]))
				}
			}
		}

		return resources
	}

	private func fungibleResourceTransferInstruction(
		witdhrawAccount: AccountAddress,
		_ resource: InvolvedFungibleResource
	) throws -> [any InstructionProtocol] {
		let accountWithdrawals: [any InstructionProtocol] = [
			CallMethod(
				receiver: witdhrawAccount,
				methodName: "withdraw",
				arguments: [
					.address(resource.address.asGeneral()),
					.decimal(.init(value: resource.totalTransferAmount.toString())),
				]
			),
		]

		let deposits: [any InstructionProtocol] = resource.accounts.flatMap { account in
			let bucket = UUID().uuidString

			let instructions: [any InstructionProtocol] = [
				TakeFromWorktop(
					amount: .init(value: account.amount.toString()),
					resourceAddress: resource.address,
					bucket: .init(value: bucket)
				),

				CallMethod(
					receiver: account.id,
					methodName: "deposit",
					arguments: [.bucket(.init(value: bucket))]
				),
			]

			return instructions
		}

		return accountWithdrawals + deposits
	}

	private func nonFungibleResourceTransferInstruction(
		witdhrawAccount: AccountAddress,
		_ resource: InvolvedNonFungibleResource
	) throws -> [any InstructionProtocol] {
		let accountWithdrawals: [any InstructionProtocol] = try [
			CallMethod(
				receiver: witdhrawAccount,
				methodName: "withdraw_non_fungibles",
				arguments: [
					.address(resource.address.asGeneral()),
					.array(.init(
						elementKind: .nonFungibleLocalId,
						elements: resource.allTokens.map {
							try .nonFungibleLocalId($0.id.toRETLocalID())
						}
					)),
				]
			),
		]

		let deposits: [any InstructionProtocol] = try resource.accounts.flatMap { account in
			let bucket = UUID().uuidString

			let instructions: [any InstructionProtocol] = try [
				TakeNonFungiblesFromWorktop(
					Set(account.tokens.map { try $0.id.toRETLocalID() }),
					resourceAddress: resource.address,
					bucket: .init(value: bucket)
				),

				CallMethod(
					receiver: account.id,
					methodName: "deposit",
					arguments: [.bucket(.init(value: bucket))]
				),
			]

			return instructions
		}

		return accountWithdrawals + deposits
	}
}

extension AccountPortfolio.NonFungibleResource.NonFungibleToken.LocalID {
	struct InvalidLocalID: Error {}

	// TODO: Remove once RET is migrated to `ash`, this is meant to be temporary
	func toRETLocalID() throws -> NonFungibleLocalId {
		guard rawValue.count >= 3 else {
			throw InvalidLocalID()
		}
		let value = String(self.rawValue.dropLast().dropFirst())
		return .init(value: value)
	}
}
