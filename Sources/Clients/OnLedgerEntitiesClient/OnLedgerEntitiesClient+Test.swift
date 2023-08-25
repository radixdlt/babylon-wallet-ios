import Prelude

extension DependencyValues {
	public var onLedgerEntitiesClient: OnLedgerEntitiesClient {
		get { self[OnLedgerEntitiesClient.self] }
		set { self[OnLedgerEntitiesClient.self] = newValue }
	}
}
