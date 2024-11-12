import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - AssetTransfer
struct AssetTransfer: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var accounts: TransferAccountList.State
		var message: AssetTransferMessage.State?
		let isMainnetAccount: Bool

		init(
			from account: Account
		) {
			self.isMainnetAccount = account.networkID == .mainnet
			self.accounts = .init(fromAccount: account)
			self.message = nil
		}
	}

	@Dependency(\.dappInteractionClient) var dappInteractionClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	init() {}

	enum ViewAction: Equatable, Sendable {
		case closeButtonTapped
		case addMessageTapped
		case backgroundTapped
		case sendTransferTapped
	}

	@CasePathable
	enum ChildAction: Equatable, Sendable {
		case message(AssetTransferMessage.Action)
		case accounts(TransferAccountList.Action)
	}

	enum DelegateAction: Equatable, Sendable {
		case dismissed
	}

	var body: some ReducerOf<Self> {
		Scope(state: \.accounts, action: /Action.child .. ChildAction.accounts) {
			TransferAccountList()
		}
		Reduce(core)
			.ifLet(\.message, action: /Action.child .. ChildAction.message) {
				AssetTransferMessage()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .addMessageTapped:
			state.message = .empty
			return .none

		case .backgroundTapped:
			if state.message?.focused == true {
				state.message?.focused = false
			}

			for id in state.accounts.receivingAccounts.ids {
				for assetID in state.accounts.receivingAccounts[id: id]?.assets.ids ?? [] {
					state.accounts.receivingAccounts[id: id]?.assets[id: assetID]?.unsetFocus()
				}
			}

			return .none

		case .sendTransferTapped:
			state.message?.focused = false

			return .run { [accounts = state.accounts, message = state.message?.message] send in
				let manifest = try await createManifest(accounts)

				Task {
					_ = await dappInteractionClient.addWalletInteraction(
						.transaction(.init(send: .init(transactionManifest: manifest, message: message))),
						.accountTransfer
					)
				}
				await send(.delegate(.dismissed))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case .closeButtonTapped:
			return .send(.delegate(.dismissed))
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
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
	var canSendTransferRequest: Bool {
		guard !accounts.receivingAccounts.isEmpty else {
			return false
		}

		return accounts.receivingAccounts.allSatisfy { receivingAccount in
			guard receivingAccount.recipient != nil else {
				return false
			}
			guard receivingAccount.isDepositEnabled else {
				return false
			}
			let fungibleAssets = receivingAccount.assets.fungibleAssets
			let nonFungibleAssets = receivingAccount.assets.nonFungibleAssets

			if !fungibleAssets.isEmpty {
				return fungibleAssets.allSatisfy { $0.transferAmount != nil && $0.totalTransferSum <= $0.balance }
			}

			return !nonFungibleAssets.isEmpty
		}
	}

	var isLoadingDepositStatus: Bool {
		accounts.receivingAccounts.contains(where: \.isLoadingDepositStatus)
	}
}

extension AssetTransfer {
	private struct InvolvedFungibleResource: Identifiable {
		struct PerAccountAmount: Identifiable {
			var amount: Decimal192
			let recipient: AccountOrAddressOf
			typealias ID = AccountAddress
			var id: ID {
				recipient.accountAddress
			}
		}

		var id: ResourceAddress {
			address
		}

		let address: ResourceAddress
		let totalTransferAmount: Decimal192
		let divisibility: UInt8?
		var accounts: IdentifiedArrayOf<PerAccountAmount>
	}

	private struct InvolvedNonFungibleResource: Identifiable {
		struct PerAccountTokens: Identifiable {
			var tokens: IdentifiedArrayOf<OnLedgerEntity.NonFungibleToken>
			let recipient: AccountOrAddressOf
			typealias ID = AccountAddress
			var id: ID {
				recipient.accountAddress
			}
		}

		var id: ResourceAddress {
			address
		}

		let address: ResourceAddress
		var accounts: IdentifiedArrayOf<PerAccountTokens>

		var allTokens: [OnLedgerEntity.NonFungibleToken] {
			accounts.flatMap(\.tokens)
		}
	}
}

extension AssetTransfer {
	private func createManifest(_ accounts: TransferAccountList.State) async throws -> TransactionManifest {
		let involvedFungibleResources = try await extractInvolvedFungibleResources(accounts.receivingAccounts)

		let fungibles: [PerAssetTransfersOfFungibleResource] = try await involvedFungibleResources.asyncMap { perAsset in
			let resourceAddress = perAsset.address

			let transfers: [PerAssetFungibleTransfer] = try await perAsset.accounts.asyncMap { transfer in
				let useTryDepositOrAbort = try await useTryDepositOrAbort(
					resource: resourceAddress,
					into: transfer.recipient
				)
				return PerAssetFungibleTransfer(
					useTryDepositOrAbort: useTryDepositOrAbort,
					amount: transfer.amount,
					recipient: transfer.recipient
				)
			}

			return PerAssetTransfersOfFungibleResource(
				resource: PerAssetFungibleResource(
					resourceAddress: resourceAddress,
					divisibility: perAsset.divisibility
				),
				transfers: transfers
			)
		}

		let involvedNonFungibles = extractInvolvedNonFungibleResource(accounts.receivingAccounts)

		let nonFungibles: [PerAssetTransfersOfNonFungibleResource] = try await involvedNonFungibles.asyncMap { perAsset in
			let resourceAddress = perAsset.address
			let transfers: [PerAssetNonFungibleTransfer] = try await perAsset.accounts.asyncMap { transfer in
				let useTryDepositOrAbort = try await useTryDepositOrAbort(
					resource: resourceAddress,
					into: transfer.recipient
				)
				return PerAssetNonFungibleTransfer(
					useTryDepositOrAbort: useTryDepositOrAbort,
					nonFungibleLocalIds: transfer.tokens.map(\.id.nonFungibleLocalId),
					recipient: transfer.recipient
				)
			}

			return PerAssetTransfersOfNonFungibleResource(
				resource: resourceAddress,
				transfers: transfers
			)
		}

		let perAssetTransfers = PerAssetTransfers(
			fromAccount: accounts.fromAccount.address,
			fungibleResources: fungibles,
			nonFungibleResources: nonFungibles
		)

		return TransactionManifest.assetsTransfers(transfers: perAssetTransfers)
	}
}

func useTryDepositOrAbort(
	resource: ResourceAddress,
	into receivingAccount: AccountOrAddressOf
) async throws -> Bool {
	if case let .profileAccount(value: userAccount) = receivingAccount {
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.accountsClient) var accountsClient

		let needsSignatureForDepositing = await needsSignatureForDepositting(into: userAccount, resource: resource)
		let isSoftwareAccount = !userAccount.isLedgerControlled
		let userHasAccessToMnemonic = userAccount.deviceFactorSourceID.map { deviceFactorSourceID in
			secureStorageClient.containsMnemonicIdentifiedByFactorSourceID(deviceFactorSourceID)
		} ?? false

		if needsSignatureForDepositing, isSoftwareAccount && userHasAccessToMnemonic || !isSoftwareAccount {
			return false
		}
	}

	return true
}

/// Determines if depositting the resource into an account requires the addition of a signature
func needsSignatureForDepositting(
	into receivingAccount: Account,
	resource resourceAddress: ResourceAddress
) async -> Bool {
	let depositSettings = receivingAccount.onLedgerSettings.thirdPartyDeposits
	let resourceException = depositSettings.assetsExceptionList?.first { $0.address == resourceAddress }?.exceptionRule

	switch (depositSettings.depositRule, resourceException) {
	// AcceptAll
	case (.acceptAll, .none):
		return false
	case (.acceptAll, .allow):
		return false
	case (.acceptAll, .deny):
		return true
	// Accept Known
	case (.acceptKnown, .allow):
		return false
	case (.acceptKnown, .none):
		// Check if the resource is known to the account
		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
		let hasResource = await (try? onLedgerEntitiesClient
			.getAccount(receivingAccount.address)
			.hasResource(resourceAddress)
		) ?? false

		return !hasResource
	case (.acceptKnown, .deny):
		return true
	// DenyAll
	case (.denyAll, .none):
		return true
	case (.denyAll, .allow):
		return false
	case (.denyAll, .deny):
		return true
	}
}

extension AssetTransfer {
	private func extractInvolvedFungibleResources(
		_ receivingAccounts: IdentifiedArrayOf<ReceivingAccount.State>
	) async throws -> IdentifiedArrayOf<InvolvedFungibleResource> {
		let allResourceAddresses: [ResourceAddress] = try receivingAccounts.flatMap {
			let addresses = try $0.assets.fungibleAssets.map {
				try ResourceAddress(validatingAddress: $0.id)
			}
			return addresses
		}
		/// Fetch additional information, for now only resource divisibility is used
		let onLedgerResources: [OnLedgerEntity.Resource] = try await onLedgerEntitiesClient.getResources(allResourceAddresses)

		var resources: IdentifiedArrayOf<InvolvedFungibleResource> = []

		for receivingAccount in receivingAccounts {
			guard let account = receivingAccount.recipient else {
				continue
			}
			let assets = receivingAccount.assets.fungibleAssets
			for fungibleAsset in assets {
				guard let transferAmount = fungibleAsset.transferAmount else {
					continue
				}
				let accountTransfer = InvolvedFungibleResource.PerAccountAmount(
					amount: transferAmount,
					recipient: account
				)

				if resources[id: fungibleAsset.resource.resourceAddress] != nil {
					resources[id: fungibleAsset.resource.resourceAddress]?.accounts.append(accountTransfer)
				} else {
					resources.append(.init(
						address: fungibleAsset.resource.resourceAddress,
						totalTransferAmount: fungibleAsset.totalTransferSum,
						divisibility: onLedgerResources.first(where: { $0.resourceAddress == fungibleAsset.resource.resourceAddress })?.divisibility,
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
			guard let account = receivingAccount.recipient else {
				continue
			}

			let accountAddress = account.accountAddress
			let assets = receivingAccount.assets.nonFungibleAssets

			for nonFungibleAsset in assets {
				if resources[id: nonFungibleAsset.resourceAddress] != nil {
					if resources[id: nonFungibleAsset.resourceAddress]?.accounts[id: accountAddress] != nil {
						resources[id: nonFungibleAsset.resourceAddress]?.accounts[id: accountAddress]?.tokens.append(nonFungibleAsset.token)
					} else {
						resources[id: nonFungibleAsset.resourceAddress]?.accounts.append(.init(
							tokens: [nonFungibleAsset.token],
							recipient: account
						))
					}
				} else {
					resources.append(.init(
						address: nonFungibleAsset.resourceAddress,
						accounts: [.init(
							tokens: [nonFungibleAsset.token],
							recipient: account
						)]
					))
				}
			}
		}

		return resources
	}
}
