import ComposableArchitecture

public struct NonFungibleResourceAsset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = String

		public let resource: OnLedgerEntity.OwnedNonFungibleResource
		public let token: OnLedgerEntity.NonFungibleToken

		var resourceAddress: ResourceAddress { resource.resourceAddress }
		public var id: ID { token.id.toRawString() }
	}

	public enum ViewAction: Equatable, Sendable {
		case resourceTapped
	}

	public enum DelegateAction: Equatable, Sendable {
		case resourceTapped
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .resourceTapped:
			.send(.delegate(.resourceTapped))
		}
	}
}
