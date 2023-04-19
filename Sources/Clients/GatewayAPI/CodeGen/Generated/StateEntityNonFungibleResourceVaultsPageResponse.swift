import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityNonFungibleResourceVaultsPageResponse")
public typealias StateEntityNonFungibleResourceVaultsPageResponse = GatewayAPI.StateEntityNonFungibleResourceVaultsPageResponse

// MARK: - GatewayAPI.StateEntityNonFungibleResourceVaultsPageResponse
extension GatewayAPI {
	public struct StateEntityNonFungibleResourceVaultsPageResponse: Codable, Hashable {
		public private(set) var ledgerState: LedgerState
		/** Total number of items in underlying collection, fragment of which is available in `items` collection. */
		public private(set) var totalCount: Int64?
		/** If specified, contains a cursor to query previous page of the `items` collection. */
		public private(set) var previousCursor: String?
		/** If specified, contains a cursor to query next page of the `items` collection. */
		public private(set) var nextCursor: String?
		public private(set) var items: [NonFungibleResourcesCollectionItemVaultAggregatedVaultItem]
		/** Bech32m-encoded human readable version of the entity's global address or hex-encoded id. */
		public private(set) var address: String
		/** Bech32m-encoded human readable version of the resource (fungible, non-fungible) global address or hex-encoded id. */
		public private(set) var resourceAddress: String

		public init(ledgerState: LedgerState, totalCount: Int64? = nil, previousCursor: String? = nil, nextCursor: String? = nil, items: [NonFungibleResourcesCollectionItemVaultAggregatedVaultItem], address: String, resourceAddress: String) {
			self.ledgerState = ledgerState
			self.totalCount = totalCount
			self.previousCursor = previousCursor
			self.nextCursor = nextCursor
			self.items = items
			self.address = address
			self.resourceAddress = resourceAddress
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case ledgerState = "ledger_state"
			case totalCount = "total_count"
			case previousCursor = "previous_cursor"
			case nextCursor = "next_cursor"
			case items
			case address
			case resourceAddress = "resource_address"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(ledgerState, forKey: .ledgerState)
			try container.encodeIfPresent(totalCount, forKey: .totalCount)
			try container.encodeIfPresent(previousCursor, forKey: .previousCursor)
			try container.encodeIfPresent(nextCursor, forKey: .nextCursor)
			try container.encode(items, forKey: .items)
			try container.encode(address, forKey: .address)
			try container.encode(resourceAddress, forKey: .resourceAddress)
		}
	}
}
