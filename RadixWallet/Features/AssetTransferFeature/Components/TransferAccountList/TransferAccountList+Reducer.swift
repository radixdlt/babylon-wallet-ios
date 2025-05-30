import ComposableArchitecture
import SwiftUI

// MARK: - TransferAccountList
struct TransferAccountList: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let fromAccount: Account
		var receivingAccounts: IdentifiedArrayOf<ReceivingAccount.State> {
			didSet {
				if receivingAccounts.count > 1, receivingAccounts[0].canBeRemoved == false {
					receivingAccounts[0].canBeRemoved = true
				} else if receivingAccounts.count == 1, receivingAccounts[0].canBeRemoved == true {
					receivingAccounts[0].canBeRemoved = false
				} else if receivingAccounts.isEmpty {
					receivingAccounts.append(.empty(canBeRemovedWhenEmpty: false))
				}
			}
		}

		@PresentationState
		var destination: Destination.State?

		init(fromAccount: Account, receivingAccounts: IdentifiedArrayOf<ReceivingAccount.State>) {
			self.fromAccount = fromAccount
			self.receivingAccounts = receivingAccounts
		}

		init(fromAccount: Account) {
			self.init(
				fromAccount: fromAccount,
				receivingAccounts: [.empty(canBeRemovedWhenEmpty: false)].asIdentified()
			)
		}
	}

	enum ViewAction: Equatable, Sendable {
		case addAccountTapped
		case addAssetCloseButtonTapped
	}

	@CasePathable
	enum ChildAction: Equatable, Sendable {
		case receivingAccount(id: ReceivingAccount.State.ID, action: ReceivingAccount.Action)
	}

	enum InternalAction: Equatable, Sendable {
		case setAllDepositStatus(accountId: ReceivingAccount.State.ID, status: Loadable<DepositStatus>)
		case setDepositStatus(accountId: ReceivingAccount.State.ID, values: DepositStatusPerResources)
	}

	struct Destination: DestinationReducer {
		struct State: Sendable, Hashable {
			let id: ReceivingAccount.State.ID
			var state: MainState
		}

		@CasePathable
		enum MainState: Sendable, Hashable {
			case chooseTransferReceiver(ChooseTransferReceiver.State)
			case addAsset(AssetsView.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case chooseTransferReceiver(ChooseTransferReceiver.Action)
			case addAsset(AssetsView.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.state, action: \.self) {
				Scope(state: \.chooseTransferReceiver, action: \.chooseTransferReceiver) {
					ChooseTransferReceiver()
				}
				Scope(state: \.addAsset, action: \.addAsset) {
					AssetsView()
				}
			}
		}
	}

	@Dependency(\.gatewayAPIClient) var gatewayAPIClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
			.forEach(\.receivingAccounts, action: /Action.child .. ChildAction.receivingAccount) {
				ReceivingAccount()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .addAccountTapped:
			state.receivingAccounts.append(.empty(canBeRemovedWhenEmpty: true))
			return .none

		case .addAssetCloseButtonTapped:
			state.destination = nil
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .receivingAccount(id: id, action: action):
			switch action {
			case .delegate(.remove):
				let account = state.receivingAccounts.remove(id: id)
				account?.assets.fungibleAssets.forEach {
					updateTotalSum(&state, resourceId: $0.id)
				}
				return .none

			case let .child(.row(resourceAddress, child: .delegate(.amountChanged))),
			     let .child(.row(resourceAddress, child: .delegate(.removed))):
				updateTotalSum(&state, resourceId: resourceAddress)
				return .none

			case .delegate(.chooseAccount):
				return navigateToChooseAccounts(&state, id: id)

			case .delegate(.addAssets):
				return navigateToSelectAssets(&state, id: id)

			default:
				return .none
			}
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		guard let id = state.destination?.id else { return .none }

		switch presentedAction {
		case let .chooseTransferReceiver(.delegate(.handleResult(recipient))):
			state.receivingAccounts[id: id]?.recipient = recipient
			state.destination = nil
			return signaturesStatusEffect(state, receivingAccountId: id)

		case .chooseTransferReceiver(.delegate(.dismiss)):
			state.destination = nil
			return .none

		case let .addAsset(.delegate(.handleSelectedAssets(selectedAssets))):
			state.destination = nil
			return handleSelectedAssets(selectedAssets, id: id, state: &state)

		default:
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setAllDepositStatus(accountId, status):
			state.receivingAccounts[id: accountId]?.setAllDepositStatus(status)
			return .none
		case let .setDepositStatus(accountId, values):
			state.receivingAccounts[id: accountId]?.updateDepositStatus(values: values)
			return .none
		}
	}
}

private extension TransferAccountList {
	func updateTotalSum(_ state: inout State, resourceId: String) {
		let totalSum = state.receivingAccounts
			.flatMap(\.assets)
			.fungibleAssets
			.filter { $0.id == resourceId }
			.compactMap(\.transferAmount)
			.reduce(0, +)

		for account in state.receivingAccounts {
			guard case var .fungibleAsset(asset) = state.receivingAccounts[id: account.id]?.assets[id: resourceId]?.kind else {
				continue
			}

			asset.totalTransferSum = totalSum
			state.receivingAccounts[id: account.id]?.assets[id: resourceId]?.kind = .fungibleAsset(asset)
		}
	}

	func handleSelectedAssets(
		_ selectedAssets: AssetsView.State.Mode.SelectedAssets,
		id: ReceivingAccount.State.ID,
		state: inout State
	) -> Effect<Action> {
		let alreadyAddedAssets = state.receivingAccounts[id: id]?.assets ?? []

		var assets: IdentifiedArrayOf<ResourceAsset.State> = []

		if let selectedXRD = selectedAssets.fungibleResources.xrdResource {
			assets.append(
				ResourceAsset.State(kind: .fungibleAsset(.init(resource: selectedXRD, isXRD: true)))
			)
		}

		assets += selectedAssets.fungibleResources.nonXrdResources.map {
			ResourceAsset.State(kind: .fungibleAsset(.init(resource: $0, isXRD: false)))
		}

		assets += selectedAssets.nonFungibleResources.flatMap { resource in
			resource.tokens.map {
				ResourceAsset.State(kind: .nonFungibleAsset(.init(
					resource: resource.resource,
					token: $0
				)))
			}
		}

		// Existing assets to keep
		let existingAssets = alreadyAddedAssets.filter(assets.contains)

		// Newly added assets
		let newAssets = assets.filter(not(existingAssets.contains))

		state.receivingAccounts[id: id]?.assets = existingAssets + newAssets

		return signaturesStatusEffect(state, receivingAccountId: id)
	}

	func navigateToChooseAccounts(_ state: inout State, id: ReceivingAccount.State.ID) -> Effect<Action> {
		let filteredAccounts = state.receivingAccounts.compactMap(\.recipient?.accountAddress) + [state.fromAccount.address]
		let chooseAccount: ChooseTransferReceiver.State = .init(
			networkID: state.fromAccount.networkID,
			chooseAccounts: .init(
				context: .assetTransfer,
				filteredAccounts: filteredAccounts,
				// Create account is very buggy when started from AssetTransfer, disable it for now.
				canCreateNewAccount: false
			)
		)

		state.destination = .init(id: id, state: .chooseTransferReceiver(chooseAccount))
		return .none
	}

	func navigateToSelectAssets(_ state: inout State, id: ReceivingAccount.State.ID) -> Effect<Action> {
		guard let assets = state.receivingAccounts[id: id]?.assets else {
			return .none
		}

		let fungibleAssets = assets.fungibleAssets
		let xrdResource = fungibleAssets.first(where: \.isXRD).map(\.resource)
		let nonXrdResources = fungibleAssets.filter(not(\.isXRD)).map(\.resource)
		let selectedFungibleResources = OnLedgerEntity.OwnedFungibleResources(
			xrdResource: xrdResource,
			nonXrdResources: nonXrdResources
		)

		let selectedNonFungibleResources = assets
			.nonFungibleAssets
			.reduce(into: IdentifiedArrayOf<AssetsView.State.Mode.SelectedAssets.NonFungibleTokensPerResource>()) { partialResult, asset in
				var resource = partialResult[id: asset.resourceAddress] ?? .init(
					resource: asset.resource,
					tokens: []
				)
				resource.tokens.append(asset.token)
				partialResult.updateOrAppend(resource)
			}

		let nftsSelectedForOtherAccounts = state.receivingAccounts
			.filter { $0.id != id }
			.flatMap(\.assets)
			.nonFungibleAssets
			.map(\.token.id)

		state.destination = .init(
			id: id,
			state: .addAsset(.init(
				account: state.fromAccount,
				mode: .selection(.init(
					fungibleResources: selectedFungibleResources,
					nonFungibleResources: selectedNonFungibleResources,
					disabledNFTs: Set(nftsSelectedForOtherAccounts)
				))
			))
		)

		return .none
	}

	func signaturesStatusEffect(_ state: State, receivingAccountId: ReceivingAccount.State.ID) -> Effect<Action> {
		guard
			let receivingAccount = state.receivingAccounts[id: receivingAccountId],
			let recipient = receivingAccount.recipient
		else {
			return .none
		}

		let resourceAddresses = Array(Set(receivingAccount.assets.map(\.resourceAddress)))
		guard !resourceAddresses.isEmpty else {
			return .none
		}

		return .run { send in
			await send(.internal(.setAllDepositStatus(accountId: receivingAccountId, status: .loading)))
			let values = switch recipient {
			case let .profileAccount(account):
				await getStatusesForProfileAccount(accountForDisplay: account, assets: receivingAccount.assets)

			case let .addressOfExternalAccount(account):
				try await getStatusesForExternalAccount(account, resourceAddresses: resourceAddresses)
			}
			await send(.internal(.setDepositStatus(accountId: receivingAccountId, values: values)))
		} catch: { error, send in
			errorQueue.schedule(error)
			await send(.internal(.setAllDepositStatus(accountId: receivingAccountId, status: .failure(error))))
		}
	}

	func getStatusesForProfileAccount(
		accountForDisplay: AccountForDisplay,
		assets: IdentifiedArrayOf<ResourceAsset.State>
	) async -> DepositStatusPerResources {
		// Shall never fail, the account has been identified as present in Profile in an
		// earlier phase.
		let account = try! await accountsClient.getAccountByAddress(accountForDisplay.address)

		return await assets.parallelMap { asset in
			let result = await needsSignatureForDepositting(
				into: account,
				resource: asset.resourceAddress
			)
			return DepositStatusPerResource(
				resourceAddress: asset.resourceAddress,
				depositStatus: result ? .additionalSignatureRequired : .allowed
			)
		}
		.asIdentified()
	}

	func getStatusesForExternalAccount(_ account: AccountAddress, resourceAddresses: [ResourceAddress]) async throws -> DepositStatusPerResources {
		let result = try await gatewayAPIClient.prevalidateDeposit(.init(accountAddress: account.address, resourceAddresses: resourceAddresses.map(\.address)))

		if let behavior = result.resourceSpecificBehaviour {
			return behavior.compactMap { item -> DepositStatusPerResource? in
				guard let address = try? ResourceAddress(validatingAddress: item.resourceAddress) else {
					return nil
				}
				return DepositStatusPerResource(
					resourceAddress: address,
					depositStatus: item.allowsTryDeposit ? .allowed : .denied
				)
			}
			.asIdentified()
		} else {
			return .init()
		}
	}
}
