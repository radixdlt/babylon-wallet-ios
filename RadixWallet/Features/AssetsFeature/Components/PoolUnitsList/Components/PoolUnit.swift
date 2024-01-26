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
			destination: Destination.State? = nil
		) {
			self.poolUnit = poolUnit
			self.resourceDetails = resourceDetails
			self.isSelected = isSelected
			self.destination = destination
		}

		@PresentationState
		var destination: Destination.State?
	}

	public enum ViewAction: Sendable, Equatable {
		case didTap
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case details(PoolUnitDetails.State)
		}

		public enum Action: Sendable, Equatable {
			case details(PoolUnitDetails.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.details, action: /Action.details) {
				PoolUnitDetails()
			}
		}
	}

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
		case .didTap:
			guard case let .success(details) = state.resourceDetails else {
				return .none
			}
			if state.isSelected != nil {
				state.isSelected?.toggle()
			} else {
				state.destination = .details(
					.init(resourcesDetails: details)
				)
			}

			return .none
		}
	}
}
