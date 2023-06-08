import AssetsFeature
import FeaturePrelude

// MARK: - TransferAccountList
public struct TransferAccountList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let fromAccount: Profile.Network.Account
		public var receivingAccounts: IdentifiedArrayOf<ReceivingAccount.State> {
			didSet {
				if receivingAccounts.count > 1, receivingAccounts[0].canBeRemoved == false {
					receivingAccounts[0].canBeRemoved = true
				}

				if receivingAccounts.count == 1, receivingAccounts[0].canBeRemoved == true {
					receivingAccounts[0].canBeRemoved = false
				}

				if receivingAccounts.isEmpty {
					receivingAccounts.append(.empty(canBeRemovedWhenEmpty: false))
				}
			}
		}

		@PresentationState
		public var destination: Destinations.State?

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
		case destination(PresentationAction<Destinations.Action>)
		case receivingAccount(id: ReceivingAccount.State.ID, action: ReceivingAccount.Action)
	}

	public enum DelegateAction: Equatable, Sendable {
		case canSendTransferRequest(Bool)
	}

	public struct Destinations: Sendable, ReducerProtocol {
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

		public var body: some ReducerProtocolOf<Self> {
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

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
			.forEach(\.receivingAccounts, action: /Action.child .. ChildAction.receivingAccount) {
				ReceivingAccount()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .addAccountTapped:
			state.receivingAccounts.append(.empty(canBeRemovedWhenEmpty: true))
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .receivingAccount(id: id, action: action):
			switch action {
			case .delegate(.remove):
				let account = state.receivingAccounts.remove(id: id)
				account?.assets.compactMap(/ResourceAsset.State.fungibleAsset).forEach {
					updateTotalSum(&state, resourceAddress: $0.resource.resourceAddress)
				}
				return .none

			case let .child(.row(resourceAddress, child: .delegate(.fungibleAsset(.amountChanged)))),
			     let .child(.row(resourceAddress, child: .delegate(.removed))):
				updateTotalSum(&state, resourceAddress: resourceAddress)
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
}

extension TransferAccountList {
	private func updateTotalSum(_ state: inout State, resourceAddress: ResourceAddress) {
		let totalSum = state.receivingAccounts
			.flatMap(\.assets)
			.compactMap(/ResourceAsset.State.fungibleAsset)
			.filter { $0.resource.resourceAddress == resourceAddress }
			.compactMap(\.transferAmount)
			.reduce(0, +)

		for account in state.receivingAccounts {
			guard case var .fungibleAsset(asset) = state.receivingAccounts[id: account.id]?.assets[id: resourceAddress] else {
				continue
			}

			asset.totalTransferSum = totalSum
			state.receivingAccounts[id: account.id]?.assets[id: resourceAddress] = .fungibleAsset(asset)
		}
	}

	private func handleSelectedAssets(
		_ selectedAssets: AssetsView.State.Mode.SelectedAssets,
		id: ReceivingAccount.State.ID,
		state: inout State
	) -> EffectTask<Action> {
		let alreadyAddedAssets = state.receivingAccounts[id: id]?.assets ?? []

		var assets: IdentifiedArrayOf<ResourceAsset.State> = []

		if let selectedXRD = selectedAssets.fungibleResources.xrdResource {
			assets.append(
				ResourceAsset.State.fungibleAsset(.init(resource: selectedXRD, isXRD: true))
			)
		}

		assets += selectedAssets.fungibleResources.nonXrdResources.map {
			ResourceAsset.State.fungibleAsset(.init(resource: $0, isXRD: false))
		}

		assets += selectedAssets.nonFungibleResources.flatMap { resource in
			resource.tokens.map {
				ResourceAsset.State.nonFungibleAsset(.init(resourceAddress: resource.resourceAddress, nftToken: $0))
			}
		}

		// Existing assets to keep
		let existingAssets = alreadyAddedAssets.filter(assets.contains)

		// Newly added assets
		let newAssets = assets.filter(not(existingAssets.contains))

		state.receivingAccounts[id: id]?.assets = existingAssets + newAssets

		return .none
	}

	private func navigateToChooseAccounts(_ state: inout State, id: ReceivingAccount.State.ID) -> EffectTask<Action> {
		let filteredAccounts = state.receivingAccounts.compactMap(\.account?.left?.address) + [state.fromAccount.address]
		let chooseAccount: ChooseReceivingAccount.State = .init(
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

	private func navigateToSelectAssets(_ state: inout State, id: ReceivingAccount.State.ID) -> EffectTask<Action> {
		guard let assets = state.receivingAccounts[id: id]?.assets else {
			return .none
		}

		let fungibleAssets = assets.compactMap(/ResourceAsset.State.fungibleAsset)
		let xrdResource = fungibleAssets.first(where: \.isXRD).map(\.resource)
		let nonXrdResources = fungibleAssets.filter(not(\.isXRD)).map(\.resource)
		let selectedFungibleResources = AccountPortfolio.FungibleResources(
			xrdResource: xrdResource,
			nonXrdResources: nonXrdResources
		)

		let selectedNonFungibleResources = assets
			.compactMap(/ResourceAsset.State.nonFungibleAsset)
			.reduce(into: IdentifiedArrayOf<AssetsView.State.Mode.SelectedAssets.NonFungibleTokensPerResource>()) { partialResult, asset in
				var resource = partialResult[id: asset.resourceAddress] ?? .init(
					resourceAddress: asset.resourceAddress,
					tokens: []
				)
				resource.tokens.append(asset.nftToken)
				partialResult.updateOrAppend(resource)
			}

		let nftsSelectedForOtherAccounts = state.receivingAccounts
			.filter { $0.id != id }
			.flatMap(\.assets)
			.compactMap(/ResourceAsset.State.nonFungibleAsset)
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
}
