import ComposableArchitecture
import SwiftUI

// MARK: - NonFungibleTokenDetails
struct NonFungibleTokenDetails: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let resourceAddress: ResourceAddress
		var resourceDetails: Loadable<OnLedgerEntity.Resource>
		let ownedResource: OnLedgerEntity.OwnedNonFungibleResource?
		let token: OnLedgerEntity.NonFungibleToken?
		let ledgerState: AtLedgerState
		let stakeClaim: OnLedgerEntitiesClient.StakeClaim?
		let isClaimStakeEnabled: Bool
		var hideResource: HideResource.State?

		init(
			resourceAddress: ResourceAddress,
			resourceDetails: Loadable<OnLedgerEntity.Resource> = .idle,
			ownedResource: OnLedgerEntity.OwnedNonFungibleResource? = nil,
			token: OnLedgerEntity.NonFungibleToken? = nil,
			ledgerState: AtLedgerState,
			stakeClaim: OnLedgerEntitiesClient.StakeClaim? = nil,
			isClaimStakeEnabled: Bool = true
		) {
			self.resourceAddress = resourceAddress
			self.resourceDetails = resourceDetails
			self.token = token
			self.ownedResource = ownedResource
			self.ledgerState = ledgerState
			self.stakeClaim = stakeClaim
			self.isClaimStakeEnabled = isClaimStakeEnabled
			if stakeClaim == nil, case let .success(resource) = resourceDetails {
				hideResource = .init(kind: .nonFungible(resourceAddress, name: resource.metadata.name))
			}
		}
	}

	enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
		case task
		case tappedClaimStake
	}

	enum InternalAction: Sendable, Equatable {
		case resourceLoadResult(TaskResult<OnLedgerEntity.Resource>)
	}

	enum DelegateAction: Sendable, Equatable {
		case tappedClaimStake(OnLedgerEntitiesClient.StakeClaim)
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case hideResource(HideResource.Action)
	}

	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
	@Dependency(\.dismiss) var dismiss

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.hideResource, action: \.child.hideResource) {
				HideResource()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			guard case .idle = state.resourceDetails else {
				return .none
			}
			state.resourceDetails = .loading
			return .run { [resourceAddress = state.resourceAddress, ledgerState = state.ledgerState] send in
				let result = await TaskResult { try await onLedgerEntitiesClient.getResource(resourceAddress, atLedgerState: ledgerState, fetchMetadata: true) }
				await send(.internal(.resourceLoadResult(result)))
			}
		case .closeButtonTapped:
			return .run { _ in
				await dismiss()
			}
		case .tappedClaimStake:
			guard let stakeClaim = state.stakeClaim else {
				return .none
			}
			return .send(.delegate(.tappedClaimStake(stakeClaim)))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .resourceLoadResult(.success(resource)):
			state.resourceDetails = .success(resource)
			if state.stakeClaim == nil {
				state.hideResource = .init(kind: .nonFungible(resource.resourceAddress, name: resource.metadata.name))
			}
			return .none
		case let .resourceLoadResult(.failure(err)):
			state.resourceDetails = .failure(err)
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .hideResource(.delegate(.didHideResource)):
			.run { _ in await dismiss() }
		default:
			.none
		}
	}
}
