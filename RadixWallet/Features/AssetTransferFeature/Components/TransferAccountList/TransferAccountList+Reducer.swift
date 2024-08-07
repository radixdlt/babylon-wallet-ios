import ComposableArchitecture
import SwiftUI

// MARK: - TransferAccountList
public struct TransferAccountList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let fromAccount: Account
		public var receivingAccounts: IdentifiedArrayOf<ReceivingAccount.State> {
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
		public var destination: Destination.State?

		public init(fromAccount: Account, receivingAccounts: IdentifiedArrayOf<ReceivingAccount.State>) {
			self.fromAccount = fromAccount
			self.receivingAccounts = receivingAccounts
		}

		public init(fromAccount: Account) {
			self.init(
				fromAccount: fromAccount,
				receivingAccounts: [.empty(canBeRemovedWhenEmpty: false)].asIdentified()
			)
		}
	}

	public enum ViewAction: Equatable, Sendable {
		case addAccountTapped
		case addAssetCloseButtonTapped
	}

	@CasePathable
	public enum ChildAction: Equatable, Sendable {
		case receivingAccount(id: ReceivingAccount.State.ID, action: ReceivingAccount.Action)
	}

	public enum DelegateAction: Equatable, Sendable {
		case canSendTransferRequest(Bool)
	}

	public enum InternalAction: Equatable, Sendable {
		case updateSignatureStatus(
			accountID: ReceivingAccount.State.ID,
			assetID: ResourceAsset.State.ID,
			signatureRequired: Bool
		)
	}

	public struct Destination: DestinationReducer {
		public struct State: Sendable, Hashable {
			let id: ReceivingAccount.State.ID
			var state: MainState
		}

		@CasePathable
		public enum MainState: Sendable, Hashable {
			case chooseAccount(ChooseReceivingAccount.State)
			case addAsset(AssetsView.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case chooseAccount(ChooseReceivingAccount.Action)
			case addAsset(AssetsView.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: \.state, action: \.self) {
				Scope(state: \.chooseAccount, action: \.chooseAccount) {
					ChooseReceivingAccount()
				}
				Scope(state: \.addAsset, action: \.addAsset) {
					AssetsView()
				}
			}
		}
	}

	@Dependency(\.gatewayAPIClient) var gatewayAPIClient

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
			.forEach(\.receivingAccounts, action: /Action.child .. ChildAction.receivingAccount) {
				ReceivingAccount()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .addAccountTapped:
			state.receivingAccounts.append(.empty(canBeRemovedWhenEmpty: true))
			return .none

		case .addAssetCloseButtonTapped:
			state.destination = nil
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
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

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		guard let id = state.destination?.id else { return .none }

		switch presentedAction {
		case let .chooseAccount(.delegate(.handleResult(recipient))):
			state.receivingAccounts[id: id]?.recipient = recipient
			state.destination = nil
			return .none

		case .chooseAccount(.delegate(.dismiss)):
			state.destination = nil
			return .none

		case let .addAsset(.delegate(.handleSelectedAssets(selectedAssets))):
			state.destination = nil
			return handleSelectedAssets(selectedAssets, id: id, state: &state)

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .updateSignatureStatus(accountID, assetID, signatureRequired):
			state.receivingAccounts[id: accountID]?.assets[id: assetID]?.additionalSignatureRequired = signatureRequired
			return .none
		}
	}
}

extension TransferAccountList {
	private func updateTotalSum(_ state: inout State, resourceId: String) {
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

	private func handleSelectedAssets(
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

		if let receivingAccount = state.receivingAccounts[id: id] {
			return determineAdditionalRequiredSignatures(receivingAccount, forAssets: newAssets)
		}
		return .none
	}

	private func navigateToChooseAccounts(_ state: inout State, id: ReceivingAccount.State.ID) -> Effect<Action> {
		let filteredAccounts = state.receivingAccounts.compactMap(\.recipient?.accountAddress) + [state.fromAccount.address]
		let chooseAccount: ChooseReceivingAccount.State = .init(
			networkID: state.fromAccount.networkID,
			chooseAccounts: .init(
				context: .assetTransfer,
				filteredAccounts: filteredAccounts,
				// Create account is very buggy when started from AssetTransfer, disable it for now.
				canCreateNewAccount: false
			)
		)

		state.destination = .init(id: id, state: .chooseAccount(chooseAccount))
		return .none
	}

	private func navigateToSelectAssets(_ state: inout State, id: ReceivingAccount.State.ID) -> Effect<Action> {
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

	private func determineAdditionalRequiredSignatures(
		_ receivingAccount: ReceivingAccount.State,
		forAssets assets: IdentifiedArrayOf<ResourceAsset.State>
	) -> Effect<Action> {
		switch receivingAccount.recipient {
		case let .profileAccount(account):
			.run { send in
				for asset in assets {
					let resourceAddress = asset.resourceAddress
					let signatureNeeded = await needsSignatureForDepositting(
						into: account,
						resource: resourceAddress
					)

					await send(.internal(.updateSignatureStatus(
						accountID: receivingAccount.id,
						assetID: asset.id,
						signatureRequired: signatureNeeded
					)))
				}
			}

		case let .addressOfExternalAccount(account):
			.run { send in
				let resourceAddresses = receivingAccount.assets.map(\.id)
				let result = try await gatewayAPIClient.prevalidateDeposit(.init(accountAddress: account.address, resourceAddresses: resourceAddresses))

				if let behavior = result.resourceSpecificBehaviour {
					for item in behavior {
						await send(.internal(.updateSignatureStatus(accountID: receivingAccount.id, assetID: item.resourceAddress, signatureRequired: !item.allowsTryDeposit)))
					}
				}
			}

		case .none:
			.none
		}
	}
}
