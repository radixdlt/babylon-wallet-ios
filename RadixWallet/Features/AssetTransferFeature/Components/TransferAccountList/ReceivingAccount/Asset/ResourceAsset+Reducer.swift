import ComposableArchitecture
import SwiftUI

// MARK: - ResourceAsset
// Higher order reducer composing all types of assets that can be transferred
public struct ResourceAsset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		@CasePathable
		public enum Kind: Sendable, Hashable {
			case fungibleAsset(FungibleResourceAsset.State)
			case nonFungibleAsset(NonFungibleResourceAsset.State)

			public var fungible: FungibleResourceAsset.State? {
				switch self {
				case let .fungibleAsset(asset): asset
				case .nonFungibleAsset: nil
				}
			}

			public var nonFungible: NonFungibleResourceAsset.State? {
				switch self {
				case let .nonFungibleAsset(asset): asset
				case .fungibleAsset: nil
				}
			}
		}

		public typealias ID = String
		public var id: ID {
			switch self.kind {
			case let .fungibleAsset(asset):
				asset.id
			case let .nonFungibleAsset(asset):
				asset.id
			}
		}

		public var kind: Kind
		public var additionalSignatureRequired: Bool = false

		@PresentationState
		public var destination: Destination.State? = nil
	}

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case fungibleAsset(FungibleResourceAsset.Action)
		case nonFungibleAsset(NonFungibleResourceAsset.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case amountChanged
		case removed
	}

	public enum ViewAction: Equatable, Sendable {
		case removeTapped
	}

	public enum InternalAction: Sendable, Hashable {
		case loadedBalance(ResourceBalance, OnLedgerEntity.NonFungibleToken? = nil)
	}

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case fungibleTokenDetails(FungibleTokenDetails.State)
			case nonFungibleTokenDetails(NonFungibleTokenDetails.State)
			case lsuDetails(LSUDetails.State)
			case poolUnitDetails(PoolUnitDetails.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case fungibleTokenDetails(FungibleTokenDetails.Action)
			case nonFungibleTokenDetails(NonFungibleTokenDetails.Action)
			case lsuDetails(LSUDetails.Action)
			case poolUnitDetails(PoolUnitDetails.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.fungibleTokenDetails, action: /Action.fungibleTokenDetails) {
				FungibleTokenDetails()
			}
			Scope(state: /State.nonFungibleTokenDetails, action: /Action.nonFungibleTokenDetails) {
				NonFungibleTokenDetails()
			}
			Scope(state: /State.lsuDetails, action: /Action.lsuDetails) {
				LSUDetails()
			}
			Scope(state: /State.poolUnitDetails, action: /Action.poolUnitDetails) {
				PoolUnitDetails()
			}
		}
	}

	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.errorQueue) var errorQueue

	public var body: some ReducerOf<Self> {
		Scope(state: \.kind, action: \.child) {
			Scope(state: \.fungibleAsset, action: \.fungibleAsset) {
				FungibleResourceAsset()
			}
			Scope(state: \.nonFungibleAsset, action: \.nonFungibleAsset) {
				NonFungibleResourceAsset()
			}
		}

		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .fungibleAsset(.delegate(.amountChanged)):
			.send(.delegate(.amountChanged))
		case .fungibleAsset(.delegate(.resourceTapped)):
			if let resource = state.kind.fungible?.resource {
				loadFungibleResourceBalance(resource: resource)
			} else {
				.none
			}

		case .nonFungibleAsset(.delegate(.resourceTapped)):
			if let nonFungible = state.kind.nonFungible {
				loadNonFungibleResourceBalance(resource: nonFungible.resource, token: nonFungible.token)
			} else {
				.none
			}
		default:
			.none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .removeTapped:
			.send(.delegate(.removed))
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedBalance(balance, token):
			switch balance.details {
			case let .fungible(details):
				state.destination = .fungibleTokenDetails(.init(
					resourceAddress: balance.resource.resourceAddress,
					resource: .success(balance.resource),
					ownedFungibleResource: state.kind.fungible?.resource,
					isXRD: details.isXRD
				))

			case let .nonFungible(details):
				state.destination = .nonFungibleTokenDetails(.init(
					resourceAddress: balance.resource.resourceAddress,
					resourceDetails: .success(balance.resource),
					ownedResource: state.kind.nonFungible?.resource,
					token: details,
					ledgerState: balance.resource.atLedgerState
				))

			case let .liquidStakeUnit(details):
				state.destination = .lsuDetails(.init(
					validator: details.validator,
					stakeUnitResource: .init(
						resource: details.resource,
						amount: .init(nominalAmount: details.amount)
					),
					xrdRedemptionValue: details.worth
				))

			case let .poolUnit(details):
				state.destination = .poolUnitDetails(.init(
					resourcesDetails: details.details
				))

			case let .stakeClaimNFT(details):
				state.destination = .nonFungibleTokenDetails(.init(
					resourceAddress: details.stakeClaimResource.resourceAddress,
					resourceDetails: .success(balance.resource),
					ownedResource: state.kind.nonFungible?.resource,
					token: token,
					ledgerState: details.stakeClaimResource.atLedgerState,
					stakeClaim: details.stakeClaimTokens.stakeClaims.first
				))
			}
			return .none
		}
	}

	private func loadFungibleResourceBalance(resource: OnLedgerEntity.OwnedFungibleResource) -> Effect<Action> {
		.run { [resourceAddress = resource.resourceAddress, resourceQuantifier = resource.resourceQuantifier] send in
			do {
				let networkId = await gatewaysClient.getCurrentNetworkID()
				let resource = try await onLedgerEntitiesClient.getResource(resourceAddress)
				let balance = try await onLedgerEntitiesClient.fungibleResourceBalance(
					resource,
					resourceQuantifier: resourceQuantifier,
					networkID: networkId
				)
				await send(.internal(.loadedBalance(balance)))
			} catch {
				errorQueue.schedule(error)
			}
		}
	}

	private func loadNonFungibleResourceBalance(resource: OnLedgerEntity.OwnedNonFungibleResource, token: OnLedgerEntity.NonFungibleToken) -> Effect<Action> {
		.run { [resourceAddress = resource.resourceAddress, resourceQuantifier = token.resourceQuantifier] send in
			do {
				let resource = try await onLedgerEntitiesClient.getResource(resourceAddress)
				if let balance = try await onLedgerEntitiesClient.nonFungibleResourceBalances(.left(resource), resourceAddress: resourceAddress, resourceQuantifier: resourceQuantifier).first {
					await send(.internal(.loadedBalance(balance, token)))
				}
			} catch {
				errorQueue.schedule(error)
			}
		}
	}
}

extension ResourceAsset.State {
	mutating func unsetFocus() {
		if case var .fungibleAsset(state) = self.kind, state.focused {
			state.focused = false
			self.kind = .fungibleAsset(state)
		}
	}
}

extension OnLedgerEntity.OwnedFungibleResource {
	fileprivate var resourceQuantifier: FungibleResourceIndicator {
		.guaranteed(decimal: amount.nominalAmount)
	}
}

extension OnLedgerEntity.NonFungibleToken {
	fileprivate var resourceQuantifier: NonFungibleResourceIndicator {
		.byIds(ids: [id.nonFungibleLocalId])
	}
}
