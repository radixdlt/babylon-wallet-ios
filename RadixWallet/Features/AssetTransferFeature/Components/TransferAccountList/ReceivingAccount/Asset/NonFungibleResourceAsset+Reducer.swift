import ComposableArchitecture

struct NonFungibleResourceAsset: Sendable, FeatureReducer {
	struct State: Sendable, Hashable, Identifiable {
		typealias ID = String

		let resource: OnLedgerEntity.OwnedNonFungibleResource
		let token: OnLedgerEntity.NonFungibleToken

		var resourceAddress: ResourceAddress { resource.resourceAddress }
		var id: ID { token.id.toRawString() }
	}

	enum ViewAction: Equatable, Sendable {
		case resourceTapped
	}

	enum DelegateAction: Equatable, Sendable {
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
