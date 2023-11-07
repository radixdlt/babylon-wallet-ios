import ComposableArchitecture
import SwiftUI

// MARK: - TransferAccountList
public struct TransferAccountList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let fromAccount: Profile.Network.Account
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

		public init(fromAccount: Profile.Network.Account, receivingAccounts: IdentifiedArrayOf<ReceivingAccount.State>) {
			self.fromAccount = fromAccount
			self.receivingAccounts = receivingAccounts
		}

		public init(fromAccount: Profile.Network.Account) {
			self.init(
				fromAccount: fromAccount,
				receivingAccounts: .init(uniqueElements: [.empty(canBeRemovedWhenEmpty: false)])
			)
		}
	}

	public enum ViewAction: Equatable, Sendable {
		case addAccountTapped
	}

	public enum ChildAction: Equatable, Sendable {
		case destination(PresentationAction<Destination.Action>)
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

	public struct Destination: Sendable, Reducer {
		public typealias State = RelayState<ReceivingAccount.State.ID, MainState>
		public typealias Action = RelayAction<ReceivingAccount.State.ID, MainAction>

		public enum MainState: Sendable, Hashable {
			case chooseAccount(ChooseReceivingAccount.State)
			case addAsset(AssetsView.State)
		}

		public enum MainAction: Sendable, Equatable {
			case chooseAccount(ChooseReceivingAccount.Action)
			case addAsset(AssetsView.Action)
		}

		public var body: some ReducerOf<Self> {
			Relay {
				Scope(state: /MainState.chooseAccount, action: /MainAction.chooseAccount) {
					ChooseReceivingAccount()
				}
				Scope(state: /MainState.addAsset, action: /MainAction.addAsset) {
					AssetsView()
				}
			}
		}
	}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destination()
			}
			.forEach(\.receivingAccounts, action: /Action.child .. ChildAction.receivingAccount) {
				ReceivingAccount()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .addAccountTapped:
			state.receivingAccounts.append(.empty(canBeRemovedWhenEmpty: true))
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

			case let .child(.row(resourceAddress, child: .delegate(.fungibleAsset(.amountChanged)))),
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

		case let .destination(.presented(.relay(id, destinationAction))):
			switch destinationAction {
			case let .chooseAccount(.delegate(.handleResult(account))):
				state.receivingAccounts[id: id]?.account = account
				state.destination = nil
				return .none

			case .chooseAccount(.delegate(.dismiss)):
				state.destination = nil
				return .none

			case let .addAsset(.delegate(.handleSelectedAssets(selectedAssets))):
				state.destination = nil
				return handleSelectedAssets(selectedAssets, id: id, state: &state)

			case .addAsset(.delegate(.dismiss)):
				state.destination = nil
				return .none

			default:
				return .none
			}
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
					resourceImage: resource.resourceImage,
					resourceName: resource.resourceName,
					resourceAddress: resource.resourceAddress,
					nftToken: $0
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
		let filteredAccounts = state.receivingAccounts.compactMap(\.account?.left?.address) + [state.fromAccount.address]
		let chooseAccount: ChooseReceivingAccount.State = .init(
			networkID: state.fromAccount.networkID,
			chooseAccounts: .init(
				selectionRequirement: .exactly(1),
				filteredAccounts: filteredAccounts,
				// Create account is very buggy when started from AssetTransfer, disable it for now.
				canCreateNewAccount: false
			)
		)

		state.destination = .relayed(id, with: .chooseAccount(chooseAccount))
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
					resourceAddress: asset.resourceAddress,
					resourceImage: asset.resourceImage,
					resourceName: asset.resourceName,
					tokens: []
				)
				resource.tokens.append(asset.nftToken)
				partialResult.updateOrAppend(resource)
			}

		let nftsSelectedForOtherAccounts = state.receivingAccounts
			.filter { $0.id != id }
			.flatMap(\.assets)
			.nonFungibleAssets
			.map(\.nftToken.id)

		state.destination = .relayed(
			id,
			with: .addAsset(.init(
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
		if case let .left(userOwnedAccount) = receivingAccount.account {
			return .run { send in
				for asset in assets {
					let resourceAddress = asset.resourceAddress
					let signatureNeeded = await needsSignatureForDepositting(into: userOwnedAccount, resource: resourceAddress)
					await send(.internal(.updateSignatureStatus(
						accountID: receivingAccount.id,
						assetID: asset.id,
						signatureRequired: signatureNeeded
					)))
				}
			}
		}
		return .none
	}
}
