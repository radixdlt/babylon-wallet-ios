import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.GatewayStatusResponse")
public typealias GatewayStatusResponse = GatewayAPI.GatewayStatusResponse

// MARK: - GatewayAPI.GatewayStatusResponse
extension GatewayAPI {
	public struct GatewayStatusResponse: Codable, Hashable {
		public private(set) var ledgerState: LedgerState
		public private(set) var releaseInfo: GatewayInfoResponseReleaseInfo

		public init(ledgerState: LedgerState, releaseInfo: GatewayInfoResponseReleaseInfo) {
			self.ledgerState = ledgerState
			self.releaseInfo = releaseInfo
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case ledgerState = "ledger_state"
			case releaseInfo = "release_info"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(ledgerState, forKey: .ledgerState)
			try container.encode(releaseInfo, forKey: .releaseInfo)
		}
	}
}
