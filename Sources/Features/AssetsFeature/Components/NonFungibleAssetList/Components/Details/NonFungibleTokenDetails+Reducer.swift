import FeaturePrelude

// MARK: - NonFungibleTokenDetails
public struct NonFungibleTokenDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let resource: OnLedgerEntity.Resource
		public let token: OnLedgerEntity.NonFungibleToken?

		public init(resource: OnLedgerEntity.Resource, token: OnLedgerEntity.NonFungibleToken? = nil) {
			self.resource = resource
			self.token = token
		}
	}

	public init() {}
}
