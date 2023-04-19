import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityDetailsResponse")
public typealias StateEntityDetailsResponse = GatewayAPI.StateEntityDetailsResponse

// MARK: - GatewayAPI.StateEntityDetailsResponse
extension GatewayAPI {
	public struct StateEntityDetailsResponse: Codable, Hashable {
		public private(set) var ledgerState: LedgerState
		public private(set) var items: [StateEntityDetailsResponseItem]

		public init(ledgerState: LedgerState, items: [StateEntityDetailsResponseItem]) {
			self.ledgerState = ledgerState
			self.items = items
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case ledgerState = "ledger_state"
			case items
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(ledgerState, forKey: .ledgerState)
			try container.encode(items, forKey: .items)
		}
	}
}
