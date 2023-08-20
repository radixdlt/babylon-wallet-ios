import Foundation
import Prelude

// MARK: - OnLedgerEntitiesClient
struct OnLedgerEntitiesClient {
	public let getResources: GetResources
}

// MARK: - OnLedgerResource
public enum OnLedgerResource: Sendable, Hashable {
	case fungible(FungibleResource)
	case nonFungible(NonFungibleResource)
}

// MARK: - OnLedgerEntitiesClient.GetResources
extension OnLedgerEntitiesClient {
	public typealias GetResources = @Sendable (OrderedSet<ResourceAddress>) async throws -> OrderedSet<OnLedgerResource>
}

extension OnLedgerEntitiesClient {
	public static let liveValue = Self.live()

	public static func live(
	) -> Self {
		Self(
			getResources: {}
		)
	}
}
