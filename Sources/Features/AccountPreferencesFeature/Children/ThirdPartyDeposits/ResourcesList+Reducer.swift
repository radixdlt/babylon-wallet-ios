import EngineKit
import FeaturePrelude
import OnLedgerEntitiesClient

// MARK: - ResourcesListMode
public enum ResourcesListMode: Hashable, Sendable {
	public typealias ExceptionRule = ThirdPartyDeposits.DepositAddressExceptionRule
	case allowDenyAssets(ExceptionRule)
	case allowDepositors
}

// MARK: - ResourcesList
public struct ResourcesList: FeatureReducer {
	public struct State: Hashable, Sendable {
		struct Resource: Hashable, Sendable {
			let iconURL: URL?
			let name: String?
			let address: ThirdPartyDeposits.DepositAddress
		}

		var resourceAddresses: OrderedSet<ThirdPartyDeposits.DepositAddress> {
			switch mode {
			case let .allowDenyAssets(exception):
				return thirdPartyDeposits.assetsExceptionList.filter { $0.value == exception }.keys
			case .allowDepositors:
				return thirdPartyDeposits.depositorsAllowList
			}
		}

		var allDepositorAddresses: OrderedSet<ThirdPartyDeposits.DepositAddress> {
			switch mode {
			case .allowDenyAssets:
				return thirdPartyDeposits.assetsExceptionList.keys
			case .allowDepositors:
				return thirdPartyDeposits.depositorsAllowList
			}
		}

		var mode: ResourcesListMode
		var thirdPartyDeposits: ThirdPartyDeposits
		var resources: [Resource]

		@PresentationState
		var destinations: Destinations.State? = nil
	}

	public enum ViewAction: Equatable {
		case onAppeared
		case addAssetTapped
		case assetRemove(ThirdPartyDeposits.DepositAddress)
		case exceptionListChanged(ThirdPartyDeposits.DepositAddressExceptionRule)
	}

	public enum ChildAction: Sendable, Equatable {
		case destinations(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case updated(ThirdPartyDeposits)
	}

	public enum InternalAction: Sendable, Equatable {
		case resourceLoaded(TaskResult<OnLedgerResource>, ThirdPartyDeposits.DepositAddress)
		case resourcesLoaded(TaskResult<[OnLedgerResource]>)
	}

	public struct Destinations: ReducerProtocol {
		public enum State: Equatable, Hashable {
			case addAsset(AddAsset.State)
			case confirmAssetDeletion(AlertState<Action.ConfirmDeletionAlert>)
		}

		public enum Action: Hashable {
			case addAsset(AddAsset.Action)
			case confirmAssetDeletion(ConfirmDeletionAlert)

			public enum ConfirmDeletionAlert: Sendable, Hashable {
				case confirmTapped(ThirdPartyDeposits.DepositAddress)
				case cancelTapped
			}
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.addAsset, action: /Action.addAsset) {
				AddAsset()
			}
		}
	}

	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destinations, action: /Action.child .. ChildAction.destinations) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .onAppeared:
			let addresses: [ResourceAddress] = state.allDepositorAddresses.map(\.resourceAddress)

			return .run { send in
				let loadResourcesResult = await TaskResult { try await onLedgerEntitiesClient.getResources(addresses) }
				await send(.internal(.resourcesLoaded(loadResourcesResult)))
			}
		case .addAssetTapped:
			state.destinations = .addAsset(.init(
				mode: state.mode,
				resourceAddress: "",
				alreadyAddedResources: state.resourceAddresses
			))
			return .none
		case let .assetRemove(resource):
			state.destinations = .confirmAssetDeletion(.confirmAssetDeletion(state.mode.removeTitle, state.mode.removeConfirmationMessage, resourceAddress: resource))
			return .none
		case let .exceptionListChanged(exception):
			state.mode = .allowDenyAssets(exception)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destinations(.presented(.addAsset(.delegate(.addAddress(list, newAsset))))):
			switch list {
			case .allowDenyAssets(.allow):
				state.thirdPartyDeposits.assetsExceptionList[newAsset] = .allow
			case .allowDenyAssets(.deny):
				state.thirdPartyDeposits.assetsExceptionList[newAsset] = .deny
			case .allowDepositors:
				state.thirdPartyDeposits.depositorsAllowList.append(newAsset)
			}
			// fetch the assest
			state.destinations = nil
			return .run { [thirdPartyDeposits = state.thirdPartyDeposits] send in
				await send(.delegate(.updated(thirdPartyDeposits)))
				let loadResourceResult = await TaskResult { try await onLedgerEntitiesClient.getResource(newAsset.resourceAddress) }
				await send(.internal(.resourceLoaded(loadResourceResult, newAsset)))
			}
		case let .destinations(.presented(.confirmAssetDeletion(.confirmTapped(resource)))):
			switch state.mode {
			case .allowDenyAssets:
				state.thirdPartyDeposits.assetsExceptionList.removeValue(forKey: resource)
			case .allowDepositors:
				state.thirdPartyDeposits.depositorsAllowList.remove(resource)
			}
			return .send(.delegate(.updated(state.thirdPartyDeposits)))
		case .destinations:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .resourceLoaded(.success(resource), newAsset):
			switch resource {
			case let .fungible(fungible):
				state.resources.append(.init(iconURL: fungible.iconURL, name: fungible.name, address: newAsset))
			case let .nonFungible(nonFungible):
				state.resources.append(.init(iconURL: nonFungible.iconURL, name: nonFungible.name, address: newAsset))
			}

			return .none
		case let .resourceLoaded(_, newAsset):
			state.resources.append(.init(iconURL: nil, name: nil, address: newAsset))
			return .none

		case let .resourcesLoaded(.success(resources)):
			state.resources = state.allDepositorAddresses.map { address in
				let resourceDetails = resources.first { $0.resourceAddress == address.resourceAddress }
				return .init(
					iconURL: nil,
					name: nil,
					address: address
				)
			}
			return .none
		case .resourcesLoaded(.failure):
			state.resources = state.allDepositorAddresses.map {
				State.Resource(iconURL: nil, name: nil, address: $0)
			}
			return .none
		}
	}
}

extension AlertState<ResourcesList.Destinations.Action.ConfirmDeletionAlert> {
	static func confirmAssetDeletion(
		_ title: String,
		_ message: String,
		resourceAddress: ThirdPartyDeposits.DepositAddress
	) -> AlertState {
		AlertState {
			TextState(title)
		} actions: {
			ButtonState(role: .destructive, action: .confirmTapped(resourceAddress)) {
				TextState(L10n.Common.remove)
			}
			ButtonState(role: .cancel, action: .cancelTapped) {
				TextState(L10n.Common.cancel)
			}
		} message: {
			TextState(message)
		}
	}
}

extension ResourcesListMode {
	var removeTitle: String {
		switch self {
		case .allowDenyAssets:
			return "Remove Asset"
		case .allowDepositors:
			return "Remove Depositor Badge"
		}
	}

	var removeConfirmationMessage: String {
		switch self {
		case .allowDenyAssets(.allow):
			return "The asset will be removed from the allow list"
		case .allowDenyAssets(.deny):
			return "The asset will be removed from the deny list"
		case .allowDepositors:
			return "The badge will be removed from the list"
		}
	}
}

extension ThirdPartyDeposits.DepositAddress {
	var resourceAddress: ResourceAddress {
		switch self {
		case let .resourceAddress(address):
			return address
		case let .nonFungibleGlobalID(nonFungibleGlobalID):
			return try! nonFungibleGlobalID.resourceAddress().asSpecific()
		}
	}
}
