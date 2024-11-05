import ComposableArchitecture
import SwiftUI

// MARK: - ResourceAsset
// Higher order reducer composing all types of assets that can be transferred
struct ResourceAsset: Sendable, FeatureReducer {
	struct State: Sendable, Hashable, Identifiable {
		@CasePathable
		enum Kind: Sendable, Hashable {
			case fungibleAsset(FungibleResourceAsset.State)
			case nonFungibleAsset(NonFungibleResourceAsset.State)

			var fungible: FungibleResourceAsset.State? {
				switch self {
				case let .fungibleAsset(asset): asset
				case .nonFungibleAsset: nil
				}
			}

			var nonFungible: NonFungibleResourceAsset.State? {
				switch self {
				case let .nonFungibleAsset(asset): asset
				case .fungibleAsset: nil
				}
			}
		}

		typealias ID = String
		var id: ID {
			switch self.kind {
			case let .fungibleAsset(asset):
				asset.id
			case let .nonFungibleAsset(asset):
				asset.id
			}
		}

		var kind: Kind
		var depositStatus: Loadable<DepositStatus> = .idle

		@PresentationState
		var destination: Destination.State? = nil
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case fungibleAsset(FungibleResourceAsset.Action)
		case nonFungibleAsset(NonFungibleResourceAsset.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case amountChanged
		case removed
	}

	enum ViewAction: Equatable, Sendable {
		case removeTapped
	}

	enum InternalAction: Sendable, Hashable {
		case loadedBalance(KnownResourceBalance, OnLedgerEntity.NonFungibleToken? = nil)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case fungibleTokenDetails(FungibleTokenDetails.State)
			case nonFungibleTokenDetails(NonFungibleTokenDetails.State)
			case lsuDetails(LSUDetails.State)
			case poolUnitDetails(PoolUnitDetails.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case fungibleTokenDetails(FungibleTokenDetails.Action)
			case nonFungibleTokenDetails(NonFungibleTokenDetails.Action)
			case lsuDetails(LSUDetails.Action)
			case poolUnitDetails(PoolUnitDetails.Action)
		}

		var body: some ReducerOf<Self> {
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

	var body: some ReducerOf<Self> {
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

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .fungibleAsset(.delegate(.amountChanged)):
			return .send(.delegate(.amountChanged))
		case .fungibleAsset(.delegate(.resourceTapped)):
			guard let resource = state.kind.fungible?.resource else {
				return .none
			}
			return loadFungibleResourceBalance(resource: resource)
		case .nonFungibleAsset(.delegate(.resourceTapped)):
			guard let nonFungible = state.kind.nonFungible else {
				return .none
			}
			return loadNonFungibleResourceBalance(resource: nonFungible.resource, token: nonFungible.token)
		default:
			return .none
		}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .removeTapped:
			.send(.delegate(.removed))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
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
					details: details,
					ledgerState: balance.resource.atLedgerState
				))

			case let .liquidStakeUnit(details):
				state.destination = .lsuDetails(.init(
					validator: details.validator,
					stakeUnitResource: .init(
						resource: details.resource,
						amount: details.amount,
						guarantee: details.guarantee?.amount
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
					details: token != nil ? .token(token!) : nil,
					ledgerState: details.stakeClaimResource.atLedgerState,
					stakeClaim: details.stakeClaimTokens.stakeClaims.first,
					isClaimStakeEnabled: false
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
				if let balance = try await onLedgerEntitiesClient.nonFungibleResourceBalances(.left(resource), resourceAddress: resourceAddress, ids: resourceQuantifier.ids).first {
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
		.guaranteed(decimal: amount.exactAmount?.nominalAmount ?? 0)
	}
}

extension OnLedgerEntity.NonFungibleToken {
	fileprivate var resourceQuantifier: NonFungibleResourceIndicator {
		.byIds(ids: [id.nonFungibleLocalId])
	}
}

// MARK: - ResourceAsset.State.DepositStatus
extension ResourceAsset.State {
	var isDepositEnabled: Bool {
		switch depositStatus {
		case .idle, .loading:
			false
		case .failure:
			// We will allow user to try the deposit and worst case fail later.
			true
		case let .success(status):
			switch status {
			case .denied:
				false
			case .allowed, .additionalSignatureRequired:
				true
			}
		}
	}
}
