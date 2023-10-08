import EngineKit
import FeaturePrelude
import OnLedgerEntitiesClient

// MARK: - PoolUnit
public struct PoolUnit: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public var id: ResourcePoolAddress {
			poolUnit.resourcePoolAddress
		}

		public struct ResourceDetails: Sendable, Hashable {
			public let poolUnitResource: OnLedgerEntity.Resource
			public let xrdResource: OnLedgerEntity.Resource?
			public let nonXrdResources: [OnLedgerEntity.Resource]

			public init(
				poolUnitResource: OnLedgerEntity.Resource,
				xrdResource: OnLedgerEntity.Resource?,
				nonXrdResources: [OnLedgerEntity.Resource]
			) {
				self.poolUnitResource = poolUnitResource
				self.xrdResource = xrdResource
				self.nonXrdResources = nonXrdResources
			}
		}

		let poolUnit: OnLedgerEntity.Account.PoolUnit
		var resourceDetails: Loadable<ResourceDetails>
		var isSelected: Bool?
		var isDataLoaded = Bool.random()

		public init(
			poolUnit: OnLedgerEntity.Account.PoolUnit,
			resourceDetails: Loadable<ResourceDetails> = .idle,
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
			.onChange(of: \.isDataLoaded) { _, _ in
				Reduce { _, _ in
					.run { send in
						await send(.view(.didTap))
					}
				}
			}
	}

	public func reduce(
		into state: inout State,
		viewAction: ViewAction
	) -> Effect<Action> {
		switch viewAction {
		case .didTap:
			if state.isSelected != nil {
				state.isSelected?.toggle()
			} else {
//				state.destination = .details(
//					.init(poolUnit: state.poolUnit, poolUnitResource: state.poolUnitResource, poolResources: state.poolResources)
//				)
			}

			return .none
		}
	}
}
