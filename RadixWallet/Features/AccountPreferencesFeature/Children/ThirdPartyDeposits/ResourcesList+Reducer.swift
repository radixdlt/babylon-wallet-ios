import ComposableArchitecture
import SwiftUI

// MARK: - ResourcesListMode
public enum ResourcesListMode: Hashable, Sendable {
	public typealias ExceptionRule = ThirdPartyDeposits.DepositAddressExceptionRule
	case allowDenyAssets(ExceptionRule)
	case allowDepositors
}

// MARK: - ResourceViewState
public struct ResourceViewState: Hashable, Sendable, Identifiable {
	public enum EngineToolkitAddress: Hashable, Sendable {
		case assetException(ThirdPartyDeposits.AssetException)
		case allowedDepositor(ThirdPartyDeposits.DepositorAddress)
	}

	public var id: EngineToolkitAddress { address }

	let iconURL: URL?
	let name: String?
	let address: EngineToolkitAddress
}

// MARK: - ResourcesList
public struct ResourcesList: FeatureReducer, Sendable {
	// MARK: State

	public struct State: Hashable, Sendable {
		let canModify: Bool

		var allDepositorAddresses: OrderedSet<ResourceViewState.EngineToolkitAddress> {
			switch mode {
			case .allowDenyAssets:
				OrderedSet(thirdPartyDeposits.assetsExceptionSet().map { .assetException($0) })
			case .allowDepositors:
				OrderedSet(thirdPartyDeposits.depositorsAllowSet().map { .allowedDepositor($0) })
			}
		}

		var resourcesForDisplay: [ResourceViewState] {
			switch mode {
			case let .allowDenyAssets(exception):
				let addresses: [ResourceViewState.EngineToolkitAddress] = thirdPartyDeposits.assetsExceptionSet()
					.filter { $0.exceptionRule == exception }
					.map { .assetException($0) }

				return loadedResources.filter { addresses.contains($0.address) }
			case .allowDepositors:
				return loadedResources
			}
		}

		var mode: ResourcesListMode
		var thirdPartyDeposits: ThirdPartyDeposits
		let networkID: NetworkID
		var loadedResources: [ResourceViewState] = []

		@PresentationState
		var destination: Destination.State? = nil
	}

	// MARK: Action

	public enum ViewAction: Equatable, Sendable {
		case task
		case addAssetTapped
		case assetRemove(ResourceViewState.EngineToolkitAddress)
		case exceptionListChanged(ThirdPartyDeposits.DepositAddressExceptionRule)
	}

	public enum DelegateAction: Equatable, Sendable {
		case updated(ThirdPartyDeposits)
	}

	public enum InternalAction: Equatable, Sendable {
		case resourceLoaded(OnLedgerEntity.Resource?, ResourceViewState.EngineToolkitAddress)
		case resourcesLoaded([OnLedgerEntity.Resource]?)
	}

	// MARK: Destination

	public struct Destination: DestinationReducer {
		public enum State: Hashable, Sendable {
			case addAsset(AddAsset.State)
			case confirmAssetDeletion(AlertState<Action.ConfirmDeletionAlert>)
		}

		public enum Action: Equatable, Sendable {
			case addAsset(AddAsset.Action)
			case confirmAssetDeletion(ConfirmDeletionAlert)

			public enum ConfirmDeletionAlert: Hashable, Sendable {
				case confirmTapped(ResourceViewState.EngineToolkitAddress)
				case cancelTapped
			}
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.addAsset, action: /Action.addAsset) {
				AddAsset()
			}
		}
	}

	// MARK: Reducer

	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			let addresses: [ResourceAddress] = state.allDepositorAddresses.map(\.resourceAddress)
			return .run { send in
				let loadResourcesResult = try? await onLedgerEntitiesClient.getResources(addresses)
				await send(.internal(.resourcesLoaded(loadResourcesResult)))
			}

		case .addAssetTapped:
			state.destination = .addAsset(.init(
				mode: state.mode,
				alreadyAddedResources: state.allDepositorAddresses,
				networkID: state.networkID
			))
			return .none

		case let .assetRemove(resource):
			state.destination = .confirmAssetDeletion(.confirmAssetDeletion(
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

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .resourceLoaded(resource, newAsset):
			state.loadedResources.append(.init(iconURL: resource?.metadata.iconURL, name: resource?.metadata.name, address: newAsset))

			switch newAsset {
			case let .assetException(resource):
				state.thirdPartyDeposits.appendToAssetsExceptionList(resource)
			case let .allowedDepositor(depositorAddress):
				state.thirdPartyDeposits.appendToDepositorsAllowList(depositorAddress)
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
					iconURL: resourceDetails?.metadata.iconURL,
					name: resourceDetails?.metadata.name,
					address: address
				)
			}
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .addAsset(.delegate(.addAddress(mode, newAsset))):
			state.mode = mode
			state.destination = nil

			return .run { send in
				let loadResourceResult = try? await onLedgerEntitiesClient.getResource(newAsset.resourceAddress)
				await send(.internal(.resourceLoaded(loadResourceResult, newAsset)))
			}

		case let .confirmAssetDeletion(.confirmTapped(resource)):
			state.loadedResources.removeAll(where: { $0.address == resource })
			switch resource {
			case let .assetException(resource):
				state.thirdPartyDeposits.updateAssetsExceptionList {
					$0?.removeAll(where: { $0.address == resource.address })
				}
			case let .allowedDepositor(depositorAddress):
				state.thirdPartyDeposits.updateDepositorsAllowList {
					$0?.remove(depositorAddress)
				}
			}

			return .send(.delegate(.updated(state.thirdPartyDeposits)))

		default:
			return .none
		}
	}
}

extension AlertState<ResourcesList.Destination.Action.ConfirmDeletionAlert> {
	static func confirmAssetDeletion(
		_ title: String,
		_ message: String,
		resourceAddress: ResourceViewState.EngineToolkitAddress
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

extension ResourceViewState.EngineToolkitAddress {
	var resourceAddress: ResourceAddress {
		switch self {
		case let .assetException(resource):
			resource.address
		case let .allowedDepositor(depositorAddress):
			depositorAddress.resourceAddress
		}
	}
}

extension ResourcesListMode {
	var removeTitle: String {
		switch self {
		case .allowDenyAssets:
			L10n.AccountSettings.SpecificAssetsDeposits.removeAsset
		case .allowDepositors:
			L10n.AccountSettings.SpecificAssetsDeposits.removeDepositor
		}
	}

	var removeConfirmationMessage: String {
		switch self {
		case .allowDenyAssets(.allow):
			L10n.AccountSettings.SpecificAssetsDeposits.removeAssetMessageAllow
		case .allowDenyAssets(.deny):
			L10n.AccountSettings.SpecificAssetsDeposits.removeAssetMessageDeny
		case .allowDepositors:
			L10n.AccountSettings.SpecificAssetsDeposits.removeBadgeMessageDepositors
		}
	}
}

extension ThirdPartyDeposits.DepositorAddress {
	var resourceAddress: ResourceAddress {
		switch self {
		case let .resourceAddress(address):
			address
		case let .nonFungibleGlobalID(nonFungibleGlobalID):
			try! nonFungibleGlobalID.resourceAddress().asSpecific()
		}
	}
}

extension ThirdPartyDeposits.AssetException {
	func updateExceptionRule(_ rule: ThirdPartyDeposits.DepositAddressExceptionRule) -> Self {
		.init(address: address, exceptionRule: rule)
	}
}
