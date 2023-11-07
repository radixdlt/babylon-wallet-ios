import ComposableArchitecture
import SwiftUI

// MARK: - FungibleAssetList
public struct FungibleAssetList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var sections: IdentifiedArrayOf<FungibleAssetList.Section.State>

		@PresentationState
		public var destination: Destination.State?

		public init(
			sections: IdentifiedArrayOf<FungibleAssetList.Section.State> = []
		) {
			self.sections = sections
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destination.Action>)
		case section(FungibleAssetList.Section.State.ID, FungibleAssetList.Section.Action)
	}

	public struct Destination: Sendable, Reducer {
		public enum State: Sendable, Hashable {
			case details(FungibleTokenDetails.State)
		}

		public enum Action: Sendable, Equatable {
			case details(FungibleTokenDetails.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.details, action: /Action.details) {
				FungibleTokenDetails()
			}
		}
	}

	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.sections, action: /Action.child .. ChildAction.section, element: {
				FungibleAssetList.Section()
			})
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destination()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .destination(.presented(.details(.delegate(.dismiss)))):
			state.destination = nil
			return .none
		case .destination:
			return .none
		case let .section(id, .delegate(.selected(token))):
			state.destination = .details(.init(
				resourceAddress: token.resourceAddress,
				ownedFungibleResource: token,
				isXRD: id == .xrd
			))
			return .none
		case .section:
			return .none
		}
	}
}
