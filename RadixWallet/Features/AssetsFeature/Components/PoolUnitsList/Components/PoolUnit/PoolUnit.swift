import ComposableArchitecture
import SwiftUI

// MARK: - PoolUnit
public struct PoolUnit: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public var id: ResourcePoolAddress {
			poolUnit.resourcePoolAddress
		}

		let poolUnit: OnLedgerEntity.Account.PoolUnit
		var resourceDetails: Loadable<OnLedgerEntitiesClient.OwnedResourcePoolDetails>
		var isSelected: Bool?

		public init(
			poolUnit: OnLedgerEntity.Account.PoolUnit,
			resourceDetails: Loadable<OnLedgerEntitiesClient.OwnedResourcePoolDetails> = .idle,
			isSelected: Bool? = nil,
			destination: Destinations.State? = nil
		) {
			self.poolUnit = poolUnit
			self.resourceDetails = resourceDetails
			self.isSelected = isSelected
			self.destination = destination
		}

		@PresentationState
		var destination: Destinations.State?
	}

	public enum ViewAction: Sendable, Equatable {
		case didTap
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public struct Destinations: Sendable, Reducer {
		public enum State: Sendable, Hashable {
			case details(PoolUnitDetails.State)
		}

		public enum Action: Sendable, Equatable {
			case details(PoolUnitDetails.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(
				state: /State.details,
				action: /Action.details,
				child: PoolUnitDetails.init
			)
		}
	}

	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(
				\.$destination,
				action: /Action.child .. ChildAction.destination,
				destination: Destinations.init
			)
	}

	public func reduce(
		into state: inout State,
		viewAction: ViewAction
	) -> Effect<Action> {
		switch viewAction {
		case .didTap:
			guard case let .success(details) = state.resourceDetails else {
				return .none
			}
			if state.isSelected != nil {
				state.isSelected?.toggle()
			} else {
				state.destination = .details(
					.init(poolUnit: state.poolUnit, resourcesDetails: details)
				)
			}

			return .none
		}
	}
}
