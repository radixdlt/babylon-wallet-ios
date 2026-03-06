import ComposableArchitecture

struct NonFungibleResourceAsset: FeatureReducer {
	struct State: Hashable, Identifiable {
		typealias ID = String

		let resource: OnLedgerEntity.OwnedNonFungibleResource
		let token: OnLedgerEntity.NonFungibleToken

		var resourceAddress: ResourceAddress {
			resource.resourceAddress
		}

		var id: ID {
			token.id.toRawString()
		}
	}

	enum ViewAction: Equatable {
		case resourceTapped
	}

	enum DelegateAction: Equatable {
		case resourceTapped
	}

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .resourceTapped:
			.send(.delegate(.resourceTapped))
		}
	}
}
