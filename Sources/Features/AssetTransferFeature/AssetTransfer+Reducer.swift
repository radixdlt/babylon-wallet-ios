import FeaturePrelude
import TransactionReviewFeature
import EngineToolkitClient

// MARK: - AssetTransfer
public struct AssetTransfer: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var accounts: TransferAccountList.State
		public var message: AssetTransferMessage.State?

                @PresentationState
                public var destination: Destinations.State?

		public init(from account: Profile.Network.Account) {
			self.accounts = .init(fromAccount: account)
			self.message = nil
		}
	}

	public init() {}

	public enum ViewAction: Equatable, Sendable {
		case closeButtonTapped
		case addMessageTapped
		case sendTransferTapped
	}

	public enum ChildAction: Equatable, Sendable {
		case message(AssetTransferMessage.Action)
		case accounts(TransferAccountList.Action)
                case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Equatable, Sendable {
		case dismissed
	}

        public struct Destinations: Sendable, ReducerProtocol {
                public enum State: Sendable, Hashable {
                        case transactionReview(TransactionReview.State)
                }

                public enum Action: Sendable, Equatable {
                        case transactionReview(TransactionReview.Action)
                }

                public var body: some ReducerProtocolOf<Self> {
                        Scope(state: /State.transactionReview, action: /Action.transactionReview) {
                                TransactionReview()
                        }
                }
        }

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.accounts,
		      action: /Action.child .. ChildAction.accounts,
		      child: { TransferAccountList() })

		Reduce(core)
			.ifLet(\.message, action: /Action.child .. ChildAction.message) {
				AssetTransferMessage()
			}
                        .ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
                                Destinations()
                        }
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .addMessageTapped:
			state.message = .empty
			return .none

		case .sendTransferTapped:
                        /*
                         # Withdrawing 330 XRD from the account component
                         CALL_METHOD
                             Address("${this_account_component_address}")
                             "withdraw"
                             Address("${xrd_resource_address}")
                             Decimal("330");

                         # Taking 150 XRD from the worktop and depositing them into Account A
                         TAKE_FROM_WORKTOP_BY_AMOUNT
                             Decimal("150")
                             Address("${xrd_resource_address}")
                             Bucket("account_a_bucket");
                         CALL_METHOD
                             Address("${account_a_component_address}")
                             "deposit"
                             Bucket("account_a_bucket");

                         # Taking 130 XRD from the worktop and depositing them into Account B
                         TAKE_FROM_WORKTOP_BY_AMOUNT
                             Decimal("130")
                             Address("${xrd_resource_address}")
                             Bucket("account_b_bucket");
                         CALL_METHOD
                             Address("${account_b_component_address}")
                             "deposit"
                             Bucket("account_b_bucket");

                         # Taking 50 XRD from the worktop and depositing them into Account C
                         TAKE_FROM_WORKTOP_BY_AMOUNT
                             Decimal("50")
                             Address("${xrd_resource_address}")
                             Bucket("account_c_bucket");
                         CALL_METHOD
                             Address("${account_c_component_address}")
                             "deposit"
                             Bucket("account_c_bucket");

                         */


                        let manifest = createManifest(state)
                        state.destination = .transactionReview(.init(transactionManifest: manifest, signTransactionPurpose: .internalManifest(.transfer), message: state.message?.message))
			return .none

		case .closeButtonTapped:
			return .send(.delegate(.dismissed))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .message(.delegate(.removed)):
			state.message = nil
			return .none

                case let .destination(.presented(.transactionReview(.delegate(.transactionCompleted(txid))))):
                        state.destination = nil
                        return .none
                        
		default:
			return .none
		}
	}

        private func createManifest(_ state: State) -> TransactionManifest {
                let involvedFungibleResources = involvedFungibleResources(state.accounts.receivingAccounts)
                let fungiblesTransferInstruction = involvedFungibleResources.flatMap {
                        fungibleResourceTransferInstruction(witdhrawAccount:state.accounts.fromAccount.address, $0)
                }

                let involvedNonFungibles = involvedNonFungibleResource(state.accounts.receivingAccounts)
                let nonFungiblesTransferInstruction = involvedNonFungibles.flatMap {
                        nonFungibleResourceTransferInstruction(witdhrawAccount:state.accounts.fromAccount.address, $0)
                }


                let manifest = TransactionManifest(instructions: .parsed(nonFungiblesTransferInstruction.map { $0.embed() }))

                @Dependency(\.engineToolkitClient) var  engineToolkitClient
                return try! engineToolkitClient.convertManifestToString(.init(version: .default, networkID: .kisharnet, manifest: manifest))
        }
}

extension AssetTransfer {
        struct InvolvedFungibleResource: Identifiable {
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

        struct InvolvedNonFungibleResource: Identifiable {
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
                        accounts.flatMap {
                                $0.tokens
                        }
                }
        }

        private func involvedNonFungibleResource(_ receivingAccounts: IdentifiedArrayOf<ReceivingAccount.State>) -> IdentifiedArrayOf<InvolvedNonFungibleResource> {
                var resources: IdentifiedArrayOf<InvolvedNonFungibleResource> = []

                for receivingAccount in receivingAccounts {
                        guard let accountAddress = receivingAccount.account?.address else {
                                continue
                        }

                        for nonFungibleAsset in receivingAccount.assets.compactMap(/ResourceAsset.State.nonFungibleAsset) {
                                if var resource = resources[id: nonFungibleAsset.resourceAddress] {
                                        if var perAccount = resource.accounts[id: accountAddress] {
                                                perAccount.tokens.append(nonFungibleAsset.nftToken)
                                        } else {
                                                resource.accounts.append(.init(id: accountAddress, tokens: [nonFungibleAsset.nftToken]))
                                        }
                                } else {
                                        resources.append(.init(address: nonFungibleAsset.resourceAddress, accounts: [.init(id: accountAddress, tokens: [nonFungibleAsset.nftToken])]))
                                }
                        }
                }

                return resources
        }

        private func involvedFungibleResources(_ receivingAccounts: IdentifiedArrayOf<ReceivingAccount.State>) -> IdentifiedArrayOf<InvolvedFungibleResource> {
                var resources: IdentifiedArrayOf<InvolvedFungibleResource> = []

                for receivingAccount in receivingAccounts {
                        guard let accountAddress = receivingAccount.account?.address else {
                                continue
                        }
                        for fungibleAsset in receivingAccount.assets.compactMap(/ResourceAsset.State.fungibleAsset) {
                                guard let transferAmount = fungibleAsset.transferAmount else {
                                        continue
                                }
                                let accountTransfer = InvolvedFungibleResource.PerAccountAmount(id: accountAddress, amount: transferAmount)

                                if var resource = resources[id: fungibleAsset.resource.resourceAddress] {
                                        resource.accounts.append(accountTransfer)
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

        private func fungibleResourceTransferInstruction(witdhrawAccount: AccountAddress, _ resource: InvolvedFungibleResource) -> [any InstructionProtocol] {
                let accountWidthraw: [any InstructionProtocol] = [
                        CallMethod(receiver: .init(address: witdhrawAccount.address),
                                   methodName: "withdraw",
                                   arguments: [
                                        .address(.init(address: resource.address.address)),
                                        .decimal(.init(value: resource.totalTransferAmount.toString())),
                                   ]
                        )
                        ]

                let deposits: [any InstructionProtocol] = resource.accounts.flatMap { account in
                        let bucket = UUID().uuidString

                        let instructions: [any InstructionProtocol] = [
                                TakeFromWorktopByAmount(
                                        amount: .init(value: account.amount.toString()),
                                        resourceAddress: .init(address: resource.address.address),
                                        bucket: .init(identifier: bucket)
                                ),

                                CallMethod(
                                        receiver: .init(address: account.id.address),
                                        methodName: "deposit",
                                        arguments: [.bucket(.init(identifier: bucket))]
                                )
                        ]

                        return instructions
                }

                return accountWidthraw + deposits
        }

        private func nonFungibleResourceTransferInstruction(witdhrawAccount: AccountAddress, _ resource: InvolvedNonFungibleResource) -> [any InstructionProtocol] {
                let accountWidthraw: [any InstructionProtocol] = try! [
                        CallMethod(receiver: .init(address: witdhrawAccount.address),
                                   methodName: "withdraw_non_fungibles",
                                   arguments: [
                                        .address(.init(address: resource.address.address)),
                                        .array(.init(elementKind: .nonFungibleLocalId, elements: resource.allTokens.map { _ in
                                                .nonFungibleLocalId(.integer(15))
                                        }))
                                   ]
                                  )
                ]

                let deposits: [any InstructionProtocol] = resource.accounts.flatMap { account in
                        let bucket = UUID().uuidString

                        let instructions: [any InstructionProtocol] = [
                                TakeFromWorktopByIds(
                                        Set(account.tokens.map { _ in .integer(15) }),
                                        resourceAddress: .init(address: resource.address.address),
                                        bucket: .init(identifier: bucket)),

                                CallMethod(
                                        receiver: .init(address: account.id.address),
                                        methodName: "deposit",
                                        arguments: [.bucket(.init(identifier: bucket))]
                                )
                        ]

                        return instructions
                }

                return accountWidthraw + deposits
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
