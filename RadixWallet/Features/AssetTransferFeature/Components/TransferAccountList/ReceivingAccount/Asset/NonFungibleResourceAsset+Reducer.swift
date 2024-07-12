import ComposableArchitecture

public struct NonFungibleResourceAsset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = String
		public var id: ID { token.id.toRawString() }

		public let resource: OnLedgerEntity.OwnedNonFungibleResource

		var resourceAddress: ResourceAddress { resource.resourceAddress }

		public let token: OnLedgerEntity.NonFungibleToken
		public var nftGlobalID: NonFungibleGlobalId {
			token.id
		}
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
