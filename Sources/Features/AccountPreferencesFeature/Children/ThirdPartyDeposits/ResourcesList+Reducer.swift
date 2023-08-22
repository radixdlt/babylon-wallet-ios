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
		struct Resource: Hashable, Sendable, Identifiable {
			var id: ThirdPartyDeposits.DepositAddress {
				address
			}

			let iconURL: URL?
			let name: String?
			let address: ThirdPartyDeposits.DepositAddress
		}

		var allDepositorAddresses: OrderedSet<ThirdPartyDeposits.DepositAddress> {
			switch mode {
			case .allowDenyAssets:
				return OrderedSet(thirdPartyDeposits.assetsExceptionList.map(\.address))
			case .allowDepositors:
				return thirdPartyDeposits.depositorsAllowList
			}
		}

		var resourcesForDisplay: [Resource] {
			switch mode {
			case let .allowDenyAssets(exception):
				let addresses = thirdPartyDeposits.assetsExceptionList.filter { $0.exceptionRule == exception }.map(\.address)
				return loadedResources.filter { addresses.contains($0.address) }
			case .allowDepositors:
				return loadedResources
			}
		}

		var mode: ResourcesListMode
		var thirdPartyDeposits: ThirdPartyDeposits
		var loadedResources: [Resource]

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
		case resourceLoaded(OnLedgerEntity.Resource?, ThirdPartyDeposits.DepositAddress)
		case resourcesLoaded([OnLedgerEntity.Resource]?)
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

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destinations(.presented(.addAsset(.delegate(.addAddress(mode, newAsset))))):
			state.mode = mode
			state.destinations = nil

			return .run { [thirdPartyDeposits = state.thirdPartyDeposits] send in
				let loadResourceResult = try? await onLedgerEntitiesClient.getResource(newAsset.resourceAddress)
				await send(.internal(.resourceLoaded(loadResourceResult, newAsset)))
			}

		case let .destinations(.presented(.confirmAssetDeletion(.confirmTapped(resource)))):
			switch state.mode {
			case .allowDenyAssets:
				state.thirdPartyDeposits.assetsExceptionList.removeAll(where: { $0.address == resource })
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
		case let .resourceLoaded(resource, newAsset):
			state.loadedResources.append(.init(iconURL: resource?.iconURL, name: resource?.name, address: newAsset))

			switch state.mode {
			case .allowDenyAssets(.allow):
				state.thirdPartyDeposits.assetsExceptionList.updateOrAppend(.init(address: newAsset, exceptionRule: .allow))
			case .allowDenyAssets(.deny):
				state.thirdPartyDeposits.assetsExceptionList.updateOrAppend(.init(address: newAsset, exceptionRule: .deny))
			case .allowDepositors:
				state.thirdPartyDeposits.depositorsAllowList.append(newAsset)
			}

			return .send(.delegate(.updated(state.thirdPartyDeposits)))

		case let .resourcesLoaded(resources):
			guard let resources else {
				state.loadedResources = state.allDepositorAddresses.map {
					State.Resource(iconURL: nil, name: nil, address: $0)
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

extension ThirdPartyDeposits.AssetException {
	func updateExceptionRule(_ rule: ThirdPartyDeposits.DepositAddressExceptionRule) -> Self {
		.init(address: address, exceptionRule: rule)
	}
}
