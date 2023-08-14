import DappInteractionClient
import EngineKit
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
	@Dependency(\.gatewaysClient) var gatewaysClient

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
			return .run { [accounts = state.accounts, message = state.message?.message] send in
				let manifest = try await createManifest(accounts)
				await dappInteractionClient.addWalletInteraction(
					.transaction(.init(
						send: .init(
							version: .default,
							transactionManifest: manifest,
							message: message
						)
					))
				)
				await send(.delegate(.dismissed))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

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

	private func createManifest(_ accounts: TransferAccountList.State) async throws -> TransactionManifest {
		let involvedFungibleResources = extractInvolvedFungibleResources(accounts.receivingAccounts)
		let fungiblesTransferInstruction = try involvedFungibleResources.map {
			try fungibleResourceTransferInstruction(witdhrawAccount: accounts.fromAccount.address, $0)
		}

		let involvedNonFungibles = extractInvolvedNonFungibleResource(accounts.receivingAccounts)
		let nonFungiblesTransferInstruction = try involvedNonFungibles.map {
			try nonFungibleResourceTransferInstruction(witdhrawAccount: accounts.fromAccount.address, $0)
		}

		let allInstructions = fungiblesTransferInstruction + nonFungiblesTransferInstruction

		let networkID = await gatewaysClient.getCurrentNetworkID()
		return try .init(
			instructions: .fromString(
				string: String(allInstructions.joined(by: "\n")),
				networkId: networkID.rawValue
			),
			blobs: []
		)
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
	) throws -> String {
		// FIXME: Temporary and ugly, until the RET provides the manifest builder
		let accountWithdrawals = [
			"""
			CALL_METHOD
			    Address("\(witdhrawAccount.address)")
			    "withdraw"
			    Address("\(resource.address.address)")
			    Decimal("\(resource.totalTransferAmount.toString())");
			""",
		]

		let deposits: [String] = resource.accounts.map { account in
			let bucket = UUID().uuidString

			return """
			TAKE_FROM_WORKTOP Address("\(resource.address.address)") Decimal("\(account.amount.toString())") Bucket("\(bucket)");
			CALL_METHOD Address("\(account.id.address)") "try_deposit_or_abort" Bucket("\(bucket)");
			"""
		}

		return String((accountWithdrawals + deposits).joined(by: "\n"))
	}

	private func nonFungibleResourceTransferInstruction(
		witdhrawAccount: AccountAddress,
		_ resource: InvolvedNonFungibleResource
	) throws -> String {
		// FIXME: Temporary and ugly, until the RET provides the manifest builder
		let localIds = try String(resource.allTokens.map {
			try "NonFungibleLocalId(\"\($0.id.localId().toString())\")"
		}.joined(by: ","))

		let accountWithdrawals = """
		CALL_METHOD
		    Address("\(witdhrawAccount.address)")
		    "withdraw_non_fungibles"
		    Address("\(resource.address.address)")
		    Array<NonFungibleLocalId>(\(localIds));
		"""
		let deposits: [String] = try resource.accounts.map { account in
			let bucket = UUID().uuidString
			let localIds = try String(account.tokens.map {
				try "NonFungibleLocalId(\"\($0.id.localId().toString())\")"
			}.joined(by: ","))

			return """
			TAKE_NON_FUNGIBLES_FROM_WORKTOP
			        Address("\(resource.address.address)")
			        Array<NonFungibleLocalId>(\(localIds))
			        Bucket(\"\(bucket)\");

			CALL_METHOD
			        Address("\(account.id)")
			        "try_deposit_or_abort"
			        Bucket("\(bucket)");
			"""
		}

		return String(([accountWithdrawals] + deposits).joined(by: "\n"))
	}
}
