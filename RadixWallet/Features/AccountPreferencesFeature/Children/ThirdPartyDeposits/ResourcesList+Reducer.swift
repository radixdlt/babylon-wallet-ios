import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - ResourcesListMode
public enum ResourcesListMode: Hashable, Sendable {
	public typealias ExceptionRule = DepositAddressExceptionRule
	case allowDenyAssets(ExceptionRule)
	case allowDepositors
}

// MARK: - ResourceViewState
public struct ResourceViewState: Hashable, Sendable, Identifiable {
	public enum Address: Hashable, Sendable {
		case assetException(AssetException)
		case allowedDepositor(ResourceOrNonFungible)
	}

	public var id: Address { address }

	let iconURL: URL?
	let name: String?
	let address: Address
}

// MARK: - ResourcesList
public struct ResourcesList: FeatureReducer, Sendable {
	// MARK: State

	public struct State: Hashable, Sendable {
		let canModify: Bool

		var allDepositorAddresses: OrderedSet<ResourceViewState.Address> {
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
				let addresses: [ResourceViewState.Address] = thirdPartyDeposits.assetsExceptionSet()
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
		case assetRemove(ResourceViewState.Address)
		case exceptionListChanged(DepositAddressExceptionRule)
	}

	public enum DelegateAction: Equatable, Sendable {
		case updated(ThirdPartyDeposits)
	}

	public enum InternalAction: Equatable, Sendable {
		case resourceLoaded(OnLedgerEntity.Resource?, ResourceViewState.Address)
		case resourcesLoaded([OnLedgerEntity.Resource]?)
	}

	// MARK: Destination

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Hashable, Sendable {
			case addAsset(AddAsset.State)
			case confirmAssetDeletion(AlertState<Action.ConfirmDeletionAlert>)
		}

		@CasePathable
		public enum Action: Equatable, Sendable {
			case addAsset(AddAsset.Action)
			case confirmAssetDeletion(ConfirmDeletionAlert)

			public enum ConfirmDeletionAlert: Hashable, Sendable {
				case confirmTapped(ResourceViewState.Address)
				case cancelTapped
			}
		}

		public var body: some ReducerOf<Self> {
			Scope(state: \.addAsset, action: \.addAsset) {
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
			state.loadedResources.append(.init(iconURL: resource?.metadata.iconURL, name: resource?.metadata.title, address: newAsset))

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
					name: resourceDetails?.metadata.title,
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
