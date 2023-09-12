import EngineKit
import FeaturePrelude
import OnLedgerEntitiesClient

// MARK: - ResourcesListMode
public enum ResourcesListMode: Hashable, Sendable {
	public typealias ExceptionRule = ThirdPartyDeposits.DepositAddressExceptionRule
	case allowDenyAssets(ExceptionRule)
	case allowDepositors
}

// MARK: - ResourceViewState
public struct ResourceViewState: Hashable, Sendable, Identifiable {
	public enum Address: Hashable, Sendable {
		case assetException(ThirdPartyDeposits.AssetException)
		case allowedDepositor(ThirdPartyDeposits.DepositorAddress)
	}

	public var id: Address { address }

	let iconURL: URL?
	let name: String?
	let address: Address
}

// MARK: - ResourcesList
public struct ResourcesList: FeatureReducer, Sendable {
	public struct State: Hashable, Sendable {
		var allDepositorAddresses: OrderedSet<ResourceViewState.Address> {
			switch mode {
			case .allowDenyAssets:
				return OrderedSet(thirdPartyDeposits.assetsExceptionList.map { .assetException($0) })
			case .allowDepositors:
				return OrderedSet(thirdPartyDeposits.depositorsAllowList.map { .allowedDepositor($0) })
			}
		}

		var resourcesForDisplay: [ResourceViewState] {
			switch mode {
			case let .allowDenyAssets(exception):
				let addresses: [ResourceViewState.Address] = thirdPartyDeposits.assetsExceptionList
					.filter { $0.exceptionRule == exception }
					.map { .assetException($0) }

				return loadedResources.filter { addresses.contains($0.address) }
			case .allowDepositors:
				return loadedResources
			}
		}

		var mode: ResourcesListMode
		var thirdPartyDeposits: ThirdPartyDeposits
		var loadedResources: [ResourceViewState] = []

		@PresentationState
		var destinations: Destinations.State? = nil
	}

	public enum ViewAction: Equatable, Sendable {
		case task
		case addAssetTapped
		case assetRemove(ResourceViewState.Address)
		case exceptionListChanged(ThirdPartyDeposits.DepositAddressExceptionRule)
	}

	public enum ChildAction: Equatable, Sendable {
		case destinations(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Equatable, Sendable {
		case updated(ThirdPartyDeposits)
	}

	public enum InternalAction: Equatable, Sendable {
		case resourceLoaded(OnLedgerEntity.Resource?, ResourceViewState.Address)
		case resourcesLoaded([OnLedgerEntity.Resource]?)
	}

	public struct Destinations: Reducer, Sendable {
		public enum State: Equatable, Hashable, Sendable {
			case addAsset(AddAsset.State)
			case confirmAssetDeletion(AlertState<Action.ConfirmDeletionAlert>)
		}

		public enum Action: Hashable, Sendable {
			case addAsset(AddAsset.Action)
			case confirmAssetDeletion(ConfirmDeletionAlert)

			public enum ConfirmDeletionAlert: Hashable, Sendable {
				case confirmTapped(ResourceViewState.Address)
				case cancelTapped
			}
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.addAsset, action: /Action.addAsset) {
				AddAsset()
			}
		}
	}

	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$destinations, action: /Action.child .. ChildAction.destinations) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			let addresses: [ResourceAddress] = state.allDepositorAddresses.map(\.resourceAddress)
			return .run { send in
				let loadResourcesResult = try? await onLedgerEntitiesClient.getResources(addresses)
				await send(.internal(.resourcesLoaded(loadResourcesResult)))
			}

		case .addAssetTapped:
			state.destinations = .addAsset(.init(
				mode: state.mode,
				alreadyAddedResources: state.allDepositorAddresses
			))
			return .none

		case let .assetRemove(resource):
			state.destinations = .confirmAssetDeletion(.confirmAssetDeletion(
				state.mode.removeTitle,
				state.mode.removeConfirmationMessage,
				resourceAddress: resource
			))
			return .none

		case let .exceptionListChanged(exception):
			state.mode = .allowDenyAssets(exception)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .destinations(.presented(.addAsset(.delegate(.addAddress(mode, newAsset))))):
			state.mode = mode
			state.destinations = nil

			return .run { send in
				let loadResourceResult = try? await onLedgerEntitiesClient.getResource(newAsset.resourceAddress)
				await send(.internal(.resourceLoaded(loadResourceResult, newAsset)))
			}

		case let .destinations(.presented(.confirmAssetDeletion(.confirmTapped(resource)))):
			state.loadedResources.removeAll(where: { $0.address == resource })
			switch resource {
			case let .assetException(resource):
				state.thirdPartyDeposits.assetsExceptionList.removeAll(where: { $0.address == resource.address })
			case let .allowedDepositor(depositorAddress):
				state.thirdPartyDeposits.depositorsAllowList.remove(depositorAddress)
			}

			return .send(.delegate(.updated(state.thirdPartyDeposits)))
		case .destinations:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .resourceLoaded(resource, newAsset):
			state.loadedResources.append(.init(iconURL: resource?.iconURL, name: resource?.name, address: newAsset))

			switch newAsset {
			case let .assetException(resource):
				state.thirdPartyDeposits.assetsExceptionList.updateOrAppend(resource)
			case let .allowedDepositor(depositorAddress):
				state.thirdPartyDeposits.depositorsAllowList.updateOrAppend(depositorAddress)
			}

			return .send(.delegate(.updated(state.thirdPartyDeposits)))

		case let .resourcesLoaded(resources):
			guard let resources else {
				state.loadedResources = state.allDepositorAddresses.map {
					ResourceViewState(iconURL: nil, name: nil, address: $0)
				}
				return .none
			}

			state.loadedResources = state.allDepositorAddresses.map { address in
				let resourceDetails = resources.first { $0.resourceAddress == address.resourceAddress }
				return .init(
					iconURL: resourceDetails?.iconURL,
					name: resourceDetails?.name,
					address: address
				)
			}
			return .none
		}
	}
}

extension AlertState<ResourcesList.Destinations.Action.ConfirmDeletionAlert> {
	static func confirmAssetDeletion(
		_ title: String,
		_ message: String,
		resourceAddress: ResourceViewState.Address
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

extension ResourceViewState.Address {
	var resourceAddress: ResourceAddress {
		switch self {
		case let .assetException(resource):
			return resource.address
		case let .allowedDepositor(depositorAddress):
			return depositorAddress.resourceAddress
		}
	}
}

extension ResourcesListMode {
	var removeTitle: String {
		switch self {
		case .allowDenyAssets:
			return L10n.AccountSettings.SpecificAssetsDeposits.removeAsset
		case .allowDepositors:
			return L10n.AccountSettings.SpecificAssetsDeposits.removeDepositor
		}
	}

	var removeConfirmationMessage: String {
		switch self {
		case .allowDenyAssets(.allow):
			return L10n.AccountSettings.SpecificAssetsDeposits.removeAssetMessageAllow
		case .allowDenyAssets(.deny):
			return L10n.AccountSettings.SpecificAssetsDeposits.removeAssetMessageDeny
		case .allowDepositors:
			return "The badge will be removed from the list" // FIXME: Strings
		}
	}
}

extension ThirdPartyDeposits.DepositorAddress {
	var resourceAddress: ResourceAddress {
		switch self {
		case let .resourceAddress(address):
			return address
		case let .nonFungibleGlobalID(nonFungibleGlobalID):
			return try! nonFungibleGlobalID.resourceAddress().asSpecific()
		}
	}
}

extension ThirdPartyDeposits.AssetException {
	func updateExceptionRule(_ rule: ThirdPartyDeposits.DepositAddressExceptionRule) -> Self {
		.init(address: address, exceptionRule: rule)
	}
}
