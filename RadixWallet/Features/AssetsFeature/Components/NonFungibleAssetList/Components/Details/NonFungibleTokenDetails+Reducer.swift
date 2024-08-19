import ComposableArchitecture
import SwiftUI

// MARK: - NonFungibleTokenDetails
public struct NonFungibleTokenDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let resourceAddress: ResourceAddress
		public var resourceDetails: Loadable<OnLedgerEntity.Resource>
		public let ownedResource: OnLedgerEntity.OwnedNonFungibleResource?
		public let token: OnLedgerEntity.NonFungibleToken?
		public let ledgerState: AtLedgerState
		public let stakeClaim: OnLedgerEntitiesClient.StakeClaim?
		public let isClaimStakeEnabled: Bool
		var hideAsset: HideAsset.State?

		public init(
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
			if let id = token?.id, stakeClaim == nil {
				hideAsset = .init(asset: .nonFungible(id))
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
		case task
		case tappedClaimStake
	}

	public enum InternalAction: Sendable, Equatable {
		case resourceLoadResult(TaskResult<OnLedgerEntity.Resource>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case tappedClaimStake(OnLedgerEntitiesClient.StakeClaim)
	}

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case hideAsset(HideAsset.Action)
	}

	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
	@Dependency(\.dismiss) var dismiss

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.hideAsset, action: \.child.hideAsset) {
				HideAsset()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .resourceLoadResult(.success(resource)):
			state.resourceDetails = .success(resource)
			return .none
		case let .resourceLoadResult(.failure(err)):
			state.resourceDetails = .failure(err)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .hideAsset(.delegate(.didHideAsset)):
			.run { _ in await dismiss() }
		default:
			.none
		}
	}
}
